defmodule CollegevalueWeb.MonthsHelpersTest do
  use ExUnit.Case, async: true

  import CollegevalueWeb.Views.Helpers

  describe "months/1" do
    test "shows one decimal under 10 months and whole months from 10 up" do
      assert months(1.5) == "1.5 months"
      assert months(2.4) == "2.4 months"
      assert months(6.0) == "6.0 months"
      assert months(9.94) == "9.9 months"
      assert months(9.96) == "10 months"
      assert months(36.4) == "36 months"
      assert months(0.02) == "under 0.1 months"
    end

    test "is N/A without a figure" do
      assert months(nil) == "N/A"
      assert months(-2) == "N/A"
    end
  end

  test "program_months/1 uses the student-loan median, not Parent PLUS" do
    program = %Collegevalue.Colleges.Discipline{stgp_debt_median: 30_000, pp_debt_median: 90_000, earnings_1yr: 60_000}
    assert program_months(program) == 6.0
    assert program_months(%{program | stgp_debt_median: -2}) == nil
  end
end
