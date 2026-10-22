defmodule Collegevalue.FieldNotes.FactsTest do
  use Collegevalue.DataCase

  alias Collegevalue.FieldNotes.Facts
  alias Collegevalue.Colleges.{College, Discipline}

  # One program per {earnings, debt}; -2 is how the import stores a suppressed figure.
  defp programs(name, figures) do
    for {earnings, debt} <- figures do
      n = System.unique_integer([:positive])
      college = Repo.insert!(%College{name: "#{name} College #{n}", unitid: n, state: "IL"})

      Repo.insert!(%Discipline{name: name, credential_level: 3, earnings_1yr: earnings, earnings_1yr_count: 30,
                               pp_debt_median: debt, college_id: college.id})
    end
  end

  describe "percentile/2" do
    test "interpolates like Postgres's percentile_cont" do
      assert Facts.percentile([10, 20, 30, 40], 0.5) == 25.0
      assert Facts.percentile([10, 20, 30, 40, 50], 0.25) == 20
      assert Facts.percentile([7], 0.75) == 7
      assert Facts.percentile([], 0.5) == nil
    end
  end

  describe "for_field/1" do
    test "is nil when no program reports earnings" do
      programs("Empty", [{-2, -2}, {-1, 1_000}])
      assert Facts.for_field("Empty") == nil
    end

    test "uses medians, so one outlier program barely moves the headline" do
      programs("Fire Protection", [{70_000, 20_000}, {72_000, 21_000}, {74_000, -2}, {76_000, 22_000}, {160_000, -2}])
      facts = Facts.for_field("Fire Protection")

      assert facts.earnings_median == 74_000
      assert facts.programs_with_earnings == 5
      assert facts.programs_with_debt == 3
      assert facts.debt_median == 21_000
    end

    test "flags the top and bottom programs and any far from the median, with the reasons" do
      programs("Fire Protection", [{30_000, -2}, {70_000, -2}, {72_000, -2}, {74_000, -2}, {76_000, -2}, {78_000, -2}, {160_000, -2}])
      flagged = Facts.for_field("Fire Protection").flagged

      assert Enum.map(flagged, & &1.earnings) == [160_000, 78_000, 76_000, 72_000, 70_000, 30_000]
      assert %{reasons: ["top_3", "above_2x_median"], debt: nil} = hd(flagged)
      assert %{reasons: ["bottom_3", "below_half_median"]} = List.last(flagged)
    end

    test "ranks majors by median debt over median earnings, lowest first" do
      programs("Cheap", List.duplicate({50_000, 10_000}, 5))
      programs("Dear", List.duplicate({30_000, 30_000}, 5))
      programs("Thin", List.duplicate({40_000, 20_000}, 4))

      assert %{rank: 1, ranked_of: 2, debt_to_earnings: 0.2} = Facts.for_field("Cheap")
      assert %{rank: 2, debt_to_earnings: 1.0} = Facts.for_field("Dear")
      assert %{rank: nil, debt_to_earnings: nil} = Facts.for_field("Thin")
    end

    test "the hash changes with the data and only with it" do
      programs("Economics", List.duplicate({45_000, 25_000}, 5))
      first = Facts.for_field("Economics")
      assert first.hash == Facts.for_field("Economics").hash
      assert first.hash == Facts.hash(first)

      programs("Economics", [{90_000, 25_000}])
      refute Facts.for_field("Economics").hash == first.hash
    end
  end
end
