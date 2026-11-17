defmodule CollegevalueWeb.FieldAnswerTest do
  use ExUnit.Case, async: true

  alias CollegevalueWeb.FieldAnswer

  defp facts(months, opts \\ []) do
    %{
      months_to_repay: %{of_major: months, programs: Keyword.get(opts, :programs, 100), p25: Keyword.get(opts, :p25, 4.0), p75: Keyword.get(opts, :p75, 8.0)},
      rank: Keyword.get(opts, :rank, 50),
      ranked_of: 200
    }
  end

  describe "verdict/1" do
    test "puts the headline on the band the major's months fall in" do
      assert FieldAnswer.verdict(facts(5.2)).headline == "Usually, yes."
      assert FieldAnswer.verdict(facts(6.0)).headline == "Usually, yes."
      assert FieldAnswer.verdict(facts(8.0)).headline == "Usually, if you borrow the typical amount."
      assert %{tone: :mixed} = FieldAnswer.verdict(facts(10.6))
      assert %{tone: :poor, headline: "Often not, on first-year pay alone."} = FieldAnswer.verdict(facts(13.7))
    end

    test "measures against the one-year rule of thumb" do
      assert hd(FieldAnswer.verdict(facts(5.0)).sentences) =~ "well inside the common rule of thumb"
      assert hd(FieldAnswer.verdict(facts(11.0)).sentences) =~ ", inside the common rule of thumb"
      assert hd(FieldAnswer.verdict(facts(13.0)).sentences) =~ ", past the common rule of thumb"
      assert hd(FieldAnswer.verdict(facts(20.0)).sentences) =~ "well past the common rule of thumb"
    end

    test "says where the major ranks, never as 100%" do
      assert "That is faster than 99% of majors." in FieldAnswer.verdict(facts(3.0, rank: 1)).sentences
      assert "That is slower than 99% of majors." in FieldAnswer.verdict(facts(20.0, rank: 200)).sentences
      assert "That is slower than 83% of majors." in FieldAnswer.verdict(facts(10.0, rank: 167)).sentences
    end

    test "says the college matters only when programs spread widely" do
      wide = FieldAnswer.verdict(facts(8.0, p25: 4.0, p75: 8.0)).sentences |> List.last()
      narrow = FieldAnswer.verdict(facts(5.2, p25: 4.5, p75: 5.9)).sentences |> List.last()

      assert wide =~ "The college matters: at a quarter of the 100 programs"
      assert narrow =~ "The college matters less than the major"
    end

    test "says no to a major paying under $36,000, whatever its debt" do
      verdict = FieldAnswer.verdict(Map.merge(facts(10.0), %{name: "Social Work", earnings_median: 31_737}))

      assert %{tone: :poor, headline: "No, not on first-year pay."} = verdict
      assert hd(verdict.sentences) == "Graduates earn a median $31,737 in their first year, under the $36,000 a bachelor's degree should lead to."
    end

    test "reads barely for pay within 5% under the line" do
      verdict = FieldAnswer.verdict(Map.merge(facts(8.8), %{name: "Teacher Education", earnings_median: 35_537}))

      assert %{tone: :mixed, headline: "Barely, on first-year pay."} = verdict
      assert hd(verdict.sentences) =~ "just under the $36,000"
    end

    test "names graduate school for majors that lead there" do
      verdict = FieldAnswer.verdict(Map.merge(facts(10.6), %{name: "Psychology, General", earnings_median: 28_486}))

      assert verdict.headline == "No, unless you go on to graduate school."
      assert List.last(verdict.sentences) =~ "graduate, medical or law school"
    end

    test "leaves a major over the line to the debt test" do
      assert FieldAnswer.verdict(Map.merge(facts(5.2), %{name: "Nursing", earnings_median: 62_698})).headline == "Usually, yes."
      assert FieldAnswer.verdict(Map.merge(facts(13.7), %{name: "X", earnings_median: 40_000})).headline == "Often not, on first-year pay alone."
    end

    test "keeps the debt test's no when it is the worse, and the pay no when debt is also poor" do
      assert FieldAnswer.verdict(Map.merge(facts(13.7), %{name: "Theatre", earnings_median: 35_000})).headline == "Often not, on first-year pay alone."
      assert FieldAnswer.verdict(Map.merge(facts(14.4), %{name: "Dance", earnings_median: 21_579})).headline == "No, not on first-year pay."
    end

    test "has no verdict without the measure" do
      assert FieldAnswer.verdict(%{months_to_repay: %{of_major: nil}}) == nil
      assert FieldAnswer.verdict(%{}) == nil
    end
  end

  describe "the evidence" do
    defp group(programs, months), do: %{programs: programs, earnings_median: 30_000, debt_median: 25_000, months_to_repay_median: months}

    test "school-type rows leave out groups too small to quote" do
      rows = FieldAnswer.control_rows(%{by_control: %{public: group(400, 9.9), private_nonprofit: group(500, 11.0), for_profit: group(2, 24.4)}, online_only: group(1, 9.0)})

      assert Enum.map(rows, & &1.label) == ["Public", "Private nonprofit"]
    end

    test "school type compares the fastest and slowest to repay" do
      rows = FieldAnswer.control_rows(%{by_control: %{public: group(400, 9.9), for_profit: group(15, 24.4)}})

      assert FieldAnswer.control_sentence(rows) == "For-profit programs take 24 months of pay to repay at the median, against 9.9 months at public ones."
    end

    test "parent loans need enough programs reporting them" do
      assert FieldAnswer.parent_sentence(%{parent_plus_over_24_months: %{programs: 29, of: 57}}) =~ "At 29 of the 57 programs that report Parent PLUS loans (51%)"
      assert FieldAnswer.parent_sentence(%{parent_plus_over_24_months: %{programs: 2, of: 4}}) == nil
    end

    test "the nearby pair puts the lower debt first and links each college it can" do
      a = %{college: "Walden University", debt: 52_781, earnings: 34_217}
      b = %{college: "University of Minnesota-Twin Cities", debt: 20_674, earnings: 34_392}
      pair = FieldAnswer.pair(%{nearby_pair: %{programs: [a, b], miles: 2}}, [%{college_name: "Walden University", unit_id: 125_231}])

      assert [%{college: "University of Minnesota-Twin Cities", unit_id: nil}, %{college: "Walden University", unit_id: 125_231}] = pair.programs
      assert pair.times == 2.6
    end
  end
end
