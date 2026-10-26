defmodule CollegevalueWeb.ValueHelpersTest do
  use ExUnit.Case, async: true

  import CollegevalueWeb.Views.Helpers

  test "years/1 shows one decimal" do
    assert years(1.8) == "1.8 years"
    assert years(2.916) == "2.9 years"
    assert years(1.0) == "1.0 year"
    assert years(0.03) == "under 0.1 years"
    assert years(nil) == "N/A"
    assert years(-2) == "N/A"
  end

  test "gap_text/1 rounds to thousands and keeps a zero gap" do
    assert gap_text(92_680) == "$93k beyond federal loans"
    assert gap_text(0) == "$0 beyond federal loans"
    assert gap_text(nil) == nil
  end

  test "income_bracket_label/1 falls back to bracket 3" do
    assert income_bracket_label(1) == "$0–30,000"
    assert income_bracket_label("5") == "$110,000 or more"
    assert income_bracket_label("bogus") == "$48,000–75,000"
  end
end
