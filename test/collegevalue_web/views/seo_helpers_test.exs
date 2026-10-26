defmodule CollegevalueWeb.SeoHelpersTest do
  use ExUnit.Case, async: true

  import CollegevalueWeb.Views.Helpers

  alias Collegevalue.{Colleges, Fields}
  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields.Field

  @yale %College{
    name: "Yale University",
    city: "New Haven",
    state: "CT",
    control: "2",
    yearly_cost: 85_120,
    debt_median: 11_648,
    earnings_median_after10: 100_533,
    fouryear_150_completion: 0.9633
  }

  # How the Scorecard import stores a college it has no figures for.
  @foreign %College{name: "Aarhus University", city: "unknown city", state: "unknown state", control: "Foreign"}
  @sentinels %College{name: "Adler University", city: "Chicago", state: "IL", control: "2",
                      yearly_cost: -1, debt_median: -2, earnings_median_after10: -1}

  describe "Colleges.has_outcomes?/1" do
    test "is true with any positive cost, debt or earnings figure" do
      assert Colleges.has_outcomes?(@yale)
      assert Colleges.has_outcomes?(%{@sentinels | debt_median: 15_000})
    end

    test "treats nil and the negative sentinels as missing" do
      refute Colleges.has_outcomes?(@foreign)
      refute Colleges.has_outcomes?(@sentinels)
    end
  end

  describe "Fields.has_outcomes?/1" do
    test "reads the Decimal averages" do
      assert Fields.has_outcomes?(%Field{debt_avg: Decimal.new("33795.2"), earn_avg: nil})
      refute Fields.has_outcomes?(%Field{debt_avg: Decimal.new(0), earn_avg: Decimal.new(-1)})
      refute Fields.has_outcomes?(%Field{})
    end
  end

  describe "college_title/1" do
    test "adds the place, so colleges that share a name get titles of their own" do
      assert college_title(@yale) == "Yale University (New Haven, CT)"

      assert college_title(%College{name: "Academy of Beauty Professionals", city: "Wyomissing", state: "PA"}) !=
               college_title(%College{name: "Academy of Beauty Professionals", city: "Mesa", state: "AZ"})
    end

    test "is the bare name when the place is unlisted" do
      assert college_title(@foreign) == "Aarhus University"
    end
  end

  describe "field_title/1" do
    test "asks the question searchers ask, with the field's name" do
      assert field_title(%Field{name: "Accounting"}) == "Is Accounting Worth It? Debt vs. Earnings by College"
      assert field_title(%Field{name: "Psychology, General"}) == "Is Psychology Worth It? Debt vs. Earnings by College"
    end
  end

  describe "college_summary/1" do
    test "states each figure the college reports" do
      summary = college_summary(@yale)

      assert summary =~ "private non-profit college in New Haven, CT"
      assert summary =~ "$85,120"
      assert summary =~ "$11,648"
      assert summary =~ "$100,533"
      assert summary =~ "96.33%"
    end

    test "leaves out the figures the college lacks" do
      summary = college_summary(%{@yale | yearly_cost: -1, fouryear_150_completion: -1.0})

      refute summary =~ "costs"
      refute summary =~ "finish within"
      assert summary =~ "$11,648"
    end

    test "is empty with no figures, even when the place is known" do
      assert college_summary(@foreign) == ""
      assert college_summary(@sentinels) == ""
    end
  end

  describe "field_summary/1" do
    test "states the count, averages and ranges" do
      field = %Field{
        name: "Computer Science",
        count: 783,
        debt_avg: Decimal.new("33795"),
        debt_min: Decimal.new("10346"),
        debt_max: Decimal.new("78433"),
        earn_avg: Decimal.new("65959"),
        earn_min: Decimal.new("26017"),
        earn_max: Decimal.new("161723")
      }

      summary = field_summary(field)

      assert summary =~ "783 colleges offer Computer Science"
      assert summary =~ "graduates who borrowed owe a median of $33,795 in federal student loans, from $10,346 at the lowest program to $78,433"
      assert summary =~ "earn $65,959 on average, from $26,017"
    end

    test "is empty when no college reports debt or earnings" do
      assert field_summary(%Field{name: "Air Force ROTC", count: 1}) == ""
    end
  end

  describe "field_question/1" do
    test "drops the Scorecard suffix and picks the article" do
      assert field_question("Psychology, General") == "Is a Psychology degree worth it?"
      assert field_question("Economics") == "Is an Economics degree worth it?"
    end
  end

  describe "field_answer/1" do
    @facts %{programs_with_earnings: 998, earnings_median: 28_486, earnings_p25: 25_741, earnings_p75: 31_146,
             all_majors_earnings_median: 37_050, debt_median: 25_532, rank: 91, ranked_of: 147, debt_to_earnings: 0.9}

    test "states the medians, the spread and the rank" do
      assert Enum.join(field_answer(@facts), " ") ==
               "Across 998 bachelor's programs that report earnings, the median pays its graduates $28,486 a year after graduation, " <>
                 "and the middle half pay between $25,741 and $31,146. The median for all majors is $37,050. " <>
                 "At the median program, graduates who borrowed owe $25,532. " <>
                 "Debt is 0.9x first-year earnings, which ranks 91st of 147 majors, where 1st carries the least debt for the pay."
    end

    test "leaves out what the data can't support" do
      sentences = field_answer(%{@facts | programs_with_earnings: 2, debt_median: nil, rank: nil})

      assert hd(sentences) =~ "a year after graduation."
      refute Enum.any?(sentences, &(&1 =~ "owe" or &1 =~ "ranks"))
    end

    test "is empty without facts" do
      assert field_answer(nil) == []
    end
  end

  describe "ordinal/1" do
    test "handles the teens" do
      assert Enum.map([1, 2, 3, 4, 11, 12, 13, 21, 112], &ordinal/1) == ~w(1st 2nd 3rd 4th 11th 12th 13th 21st 112th)
    end
  end
end
