defmodule Collegevalue.ParentPlusWarningTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Collegevalue.Fields
  alias CollegevalueWeb.{DataComponents, Views.Helpers}

  describe "Fields.parent_plus_warning/2" do
    test "flags a Parent PLUS median past 24 months of first-year pay" do
      assert Fields.parent_plus_warning_months() == 24
      # 81,077 / (17,690 / 12) = 55 months.
      assert_in_delta Fields.parent_plus_warning(81_077, 17_690), 55.0, 0.1
      assert Fields.parent_plus_warning(50_001, 25_000) > 24
    end

    test "does not flag at or under the threshold" do
      assert Fields.parent_plus_warning(50_000, 25_000) == nil
      assert Fields.parent_plus_warning(10_000, 60_000) == nil
    end

    test "is nil when either figure is missing (stored as -2, -1, 0 or nil)" do
      for missing <- [-2, -1, 0, nil] do
        assert Fields.parent_plus_warning(missing, 20_000) == nil
        assert Fields.parent_plus_warning(90_000, missing) == nil
      end
    end
  end

  test "parent_plus_note/2 names the median and the months of pay" do
    assert Helpers.parent_plus_note(81_077, 17_690) ==
             "Parents who borrowed owed a median of $81,077 (55 months of pay)."

    assert Helpers.parent_plus_note(-2, 17_690) == nil
  end

  describe "months_cell/1" do
    test "shows the student figure, with the parent warning beneath it" do
      html = render_component(&DataComponents.months_cell/1, value: 6.0, parent_debt: 81_077, earnings: 17_690)

      assert html =~ "6.0 months"
      assert html =~ "Parent loans"
      assert html =~ "$81,077 (55 months of pay)"
    end

    test "shows no warning without a large Parent PLUS median" do
      refute render_component(&DataComponents.months_cell/1, value: 6.0, parent_debt: 10_000, earnings: 60_000) =~ "Parent loans"
      refute render_component(&DataComponents.months_cell/1, value: 6.0) =~ "Parent loans"
    end
  end
end
