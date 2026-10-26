defmodule Collegevalue.ProgramDebtTest do
  @moduledoc """
  A program's debt is its median federal student-loan debt
  (`stgp_debt_median`). Parent PLUS loans (`pp_debt_*`) and the college-wide
  median (`colleges.debt_median`) describe other borrowers, so neither may
  stand in for it.
  """
  use Collegevalue.DataCase

  alias Collegevalue.{Calculator, Colleges, Fields}
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Location.Zipcode

  # Every college sits at the test zip code, with a large college-wide debt
  # and Parent PLUS figures that would change any result that used them.
  defp program(college, attrs) do
    n = System.unique_integer([:positive])

    college =
      Repo.insert!(%College{name: college, unitid: n, state: "NY", latitude: 40.75, longitude: -73.99,
                            debt_median: 99_000, earnings_median_after10: 80_000, netprice_3: 20_000})

    Repo.insert!(%Discipline{name: attrs[:name] || "Economics", credential_level: 3, earnings_1yr: attrs[:earnings],
                             stgp_debt_median: attrs[:debt], stgp_debt_mean: attrs[:debt],
                             pp_debt_median: 60_000, pp_debt_mean: 60_000, college_id: college.id})
  end

  setup do
    program("Student Loans U", earnings: 60_000, debt: 30_000)
    # Parent PLUS and college debt only: no student-loan figure.
    program("Parent Plus College", earnings: 90_000, debt: -2)
    program("Cheap State", earnings: 50_000, debt: 10_000)
    :ok
  end

  describe "Fields.get_bachelors_months_to_repay/2" do
    test "ranks by months of first-year pay to clear the student-loan median, fewest first" do
      ranks = Fields.get_bachelors_months_to_repay("fastest", 10)

      # 10,000 / (50,000 / 12) = 2.4 months; 30,000 / (60,000 / 12) = 6 months.
      assert Enum.map(ranks, &{&1.college_name, &1.cost, &1.payoff}) ==
               [{"Cheap State", 10_000, 50_000}, {"Student Loans U", 30_000, 60_000}]

      assert_in_delta hd(ranks).months, 2.4, 1.0e-9
      assert_in_delta List.last(ranks).months, 6.0, 1.0e-9
    end

    test "leaves out programs without a student-loan figure, whatever their Parent PLUS or college debt" do
      names = Fields.get_bachelors_months_to_repay("fastest", 10) |> Enum.map(& &1.college_name)
      refute "Parent Plus College" in names
    end

    test "slowest reverses the order" do
      assert ["Student Loans U", "Cheap State"] ==
               Fields.get_bachelors_months_to_repay("slowest", 10) |> Enum.map(& &1.college_name)
    end

    test "the SQL figure matches Fields.months_to_repay/2" do
      for rank <- Fields.get_bachelors_months_to_repay("fastest", 10),
          do: assert_in_delta(rank.months, Fields.months_to_repay(rank.cost, rank.payoff), 1.0e-9)
    end
  end

  describe "Fields.months_to_repay/2" do
    test "is debt over one month of first-year pay, and nil without both figures" do
      assert Fields.months_to_repay(30_000, 60_000) == 6.0
      assert Fields.months_to_repay(-2, 60_000) == nil
      assert Fields.months_to_repay(30_000, -2) == nil
      assert Fields.months_to_repay(nil, 60_000) == nil
    end
  end

  describe "Fields.get_bachelors_earnings/3" do
    test "shows no debt, not the college's, for a program without a student-loan figure" do
      [first | _] = ranks = Fields.get_bachelors_earnings("top", 10)

      assert %{college_name: "Parent Plus College", cost: nil, diff: nil, months: nil} = first
      assert length(ranks) == 3
      assert Enum.find(ranks, &(&1.college_name == "Cheap State")).cost == 10_000
    end

    test "require_debt keeps only programs with a student-loan figure" do
      ranks = Fields.get_bachelors_earnings("top", 10, require_debt: true)
      refute Enum.any?(ranks, &(&1.college_name == "Parent Plus College"))
      assert length(ranks) == 2
    end
  end

  test "the fields roll-up averages program student-loan medians" do
    field = Fields.get_field!("Economics")
    assert Decimal.equal?(field.debt_avg, 20_000)
    assert Decimal.equal?(field.debt_min, 10_000)
    assert Decimal.equal?(field.debt_max, 30_000)
  end

  test "a college's majors carry the student-loan figures" do
    majors = Colleges.get_majors_by_field("Economics")
    assert majors |> Enum.map(& &1.debt_median) |> Enum.sort() == [-2, 10_000, 30_000]
    refute Enum.any?(majors, &(&1.debt_mean == 60_000))
  end

  test "the calculator uses the program's student-loan debt and never the college's" do
    Repo.insert!(%Zipcode{zipcode: "10001", latitude: 40.75, longitude: -73.99})

    results = Calculator.calculate(%{income_band: 3, major: "Economics", zip: "10001", distance: 25})
    by_name = Map.new(results, &{&1.college_name, &1})

    assert %{debt_used: 30_000, debt_source: :major, roi_debt: 50_000} = by_name["Student Loans U"]
    assert %{debt_used: nil, debt_source: nil, roi_debt: nil, debt_to_earnings_ratio: nil} = by_name["Parent Plus College"]
  end
end
