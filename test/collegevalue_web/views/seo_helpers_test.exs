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
      assert summary =~ "average federal debt of $33,795, from $10,346 at the lowest program to $78,433"
      assert summary =~ "earn $65,959 on average, from $26,017"
    end

    test "is empty when no college reports debt or earnings" do
      assert field_summary(%Field{name: "Air Force ROTC", count: 1}) == ""
    end
  end
end
