defmodule Collegevalue.NetPriceValueTest do
  @moduledoc """
  Four-year cost, the gap after federal loans and the value ranking (years
  of first-year pay to cover four years of net price), by family-income
  bracket.
  """
  use Collegevalue.DataCase

  alias Collegevalue.Fields
  alias Collegevalue.Colleges.{College, Discipline}

  defp program(college, attrs) do
    c =
      Repo.insert!(%College{name: college, unitid: System.unique_integer([:positive]), yearly_cost: attrs[:sticker],
                            netprice_3: attrs[:np3], netprice_5: attrs[:np5]})

    Repo.insert!(%Discipline{name: "Economics", credential_level: 3, earnings_1yr: attrs[:earnings],
                             stgp_debt_median: attrs[:debt], pp_debt_median: -2, college_id: c.id})
  end

  setup do
    # Bracket 3 years: 4 x 2,167 / 80,000 = 0.11; 4 x 15,000 / 30,000 = 2.0; 4 x 29,170 / 40,000 = 2.92.
    # Bracket 5 years: 0.8 (No Price 3), 1.5, 2.67, 4.5.
    program("Ithaca Test", np3: 29_170, np5: 45_000, sticker: 82_750, debt: 24_000, earnings: 40_000)
    program("Harvard Test", np3: 2_167, np5: 30_000, sticker: 80_000, debt: 24_000, earnings: 80_000)
    program("Middle Test", np3: 15_000, np5: 20_000, sticker: 50_000, debt: 10_000, earnings: 30_000)
    program("No Price 3", np3: -2, np5: 10_000, sticker: -2, debt: 20_000, earnings: 50_000)
    program("No Earnings", np3: 1_000, np5: 1_000, sticker: 9_000, debt: 5_000, earnings: -2)
    :ok
  end

  defp names(ranks), do: Enum.map(ranks, & &1.college_name)

  describe "Fields.income_bracket/1" do
    test "takes 1 to 5, as integers or URL strings" do
      for b <- 1..5 do
        assert Fields.income_bracket(b) == b
        assert Fields.income_bracket(Integer.to_string(b)) == b
      end
    end

    test "falls back to bracket 3 for anything else" do
      for bad <- ["0", "6", "-1", "abc", "3abc", "", " 4", nil, 7, 2.0, %{}] do
        assert Fields.income_bracket(bad) == 3, "#{inspect(bad)} should fall back to 3"
      end
    end
  end

  describe "Fields.gap_after_loans/2" do
    test "is four years of net price less the student-loan median" do
      # Ithaca: 4 x 29,170 - 24,000 = 92,680.
      assert Fields.gap_after_loans(29_170, 24_000) == 92_680
    end

    test "never goes below 0" do
      # Harvard: 4 x 2,167 = 8,668, well under 24,000 of loans.
      assert Fields.gap_after_loans(2_167, 24_000) == 0
    end

    test "is nil when either figure is missing" do
      for missing <- [-2, -1, 0, nil] do
        assert Fields.gap_after_loans(missing, 24_000) == nil
        assert Fields.gap_after_loans(29_170, missing) == nil
      end
    end
  end

  test "four_year_cost/1 and value_years/2 skip missing figures" do
    assert Fields.four_year_cost(29_170) == 116_680
    assert Fields.four_year_cost(-2) == nil
    assert Fields.value_years(15_000, 30_000) == 2.0
    assert Fields.value_years(-2, 30_000) == nil
    assert Fields.value_years(15_000, -2) == nil
  end

  test "net_price/2 reads the bracket's column and drops sentinels" do
    college = %College{netprice_3: 29_170, netprice_5: -2}
    assert Fields.net_price(college, 3) == 29_170
    assert Fields.net_price(college, 5) == nil
    assert Fields.net_price(college, "junk") == 29_170
  end

  describe "Fields.get_bachelors_value/3" do
    test "best puts the fewest years of pay first, and leaves out missing net price or earnings" do
      assert names(Fields.get_bachelors_value("best", 10, 3)) == ["Harvard Test", "Middle Test", "Ithaca Test"]
    end

    test "worst reverses the order" do
      assert names(Fields.get_bachelors_value("worst", 10, 3)) == ["Ithaca Test", "Middle Test", "Harvard Test"]
    end

    test "uses the bracket's net price" do
      assert names(Fields.get_bachelors_value("best", 10, 5)) == ["No Price 3", "Harvard Test", "Middle Test", "Ithaca Test"]
    end

    test "the SQL figure matches Fields.value_years/2, and the row carries cost and sticker" do
      for bracket <- [3, 5], rank <- Fields.get_bachelors_value("best", 10, bracket) do
        assert_in_delta rank.value_years, Fields.value_years(rank.net_price, rank.payoff), 1.0e-9
      end

      ithaca = Enum.find(Fields.get_bachelors_value("best", 10, 3), &(&1.college_name == "Ithaca Test"))
      assert %{net_price: 29_170, sticker: 82_750, cost: 24_000} = ithaca
    end
  end

  test "the repayment ranking carries the bracket's net price, nil when missing" do
    ranks = Fields.get_bachelors_months_to_repay("fastest", 10, 3)
    assert Enum.find(ranks, &(&1.college_name == "No Price 3")).net_price == nil
    assert Enum.find(ranks, &(&1.college_name == "No Price 3")).sticker == nil
    assert Enum.find(ranks, &(&1.college_name == "No Price 3")).value_years == nil
    assert Enum.find(Fields.get_bachelors_months_to_repay("fastest", 10, 5), &(&1.college_name == "No Price 3")).net_price == 10_000
  end
end
