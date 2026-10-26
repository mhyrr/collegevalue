defmodule CollegevalueWeb.FieldValueControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}

  setup do
    for {college, np3, np5, sticker, debt, earnings} <- [
          {"Ithaca Test", 29_170, 45_000, 82_750, 24_000, 40_000},
          {"Harvard Test", 2_167, 30_000, 80_000, 24_000, 80_000},
          {"Middle Test", 15_000, 20_000, 50_000, 10_000, 30_000},
          {"No Price Test", -2, 10_000, -2, 20_000, 50_000}
        ] do
      c = Repo.insert!(%College{name: college, unitid: System.unique_integer([:positive]), yearly_cost: sticker,
                                netprice_3: np3, netprice_5: np5})

      Repo.insert!(%Discipline{name: "Economics", credential_level: 3, earnings_1yr: earnings,
                               stgp_debt_median: debt, pp_debt_median: -2, college_id: c.id})
    end

    :ok
  end

  defp tbody(html), do: html |> String.split("<tbody") |> List.last()
  defp order(html), do: Regex.scan(~r/(Ithaca|Harvard|Middle|No Price) Test/, tbody(html)) |> Enum.map(&Enum.at(&1, 1)) |> Enum.uniq()
  defp row(html, college), do: tbody(html) |> String.split("<tr") |> Enum.find(&(&1 =~ "#{college} Test"))

  test "defaults to bracket 3, names it, and shows the four-year cost in place of tuition", %{conn: conn} do
    html = conn |> get("/fields/rank") |> html_response(200)

    assert html =~ "Family income"
    assert html =~ "for families earning $48,000–75,000"
    assert html =~ ~s(<option selected value="3">)
    assert html =~ "4-Year Cost"
    refute html =~ ">Tuition<"
    assert html =~ "housing, food and books"
    assert html =~ "rather than each major"
    assert html =~ "four years"
    assert html =~ "closer to the sticker price"

    ithaca = row(html, "Ithaca")
    assert ithaca =~ "$116,680"
    assert ithaca =~ "Sticker: $331k"
    assert ithaca =~ "$93k beyond federal loans"
    assert ithaca =~ "2.9 years"

    assert row(html, "Harvard") =~ "$0 beyond federal loans"
  end

  test "a missing net price or sticker shows No data and no gap", %{conn: conn} do
    no_price = conn |> get("/fields/rank") |> html_response(200) |> row("No Price")

    assert no_price =~ "No data"
    assert no_price =~ "Sticker: No data"
    refute no_price =~ "beyond federal loans"
    refute no_price =~ "$-8"
  end

  test "income=5 switches the cost to bracket 5", %{conn: conn} do
    html = conn |> get("/fields/rank?income=5") |> html_response(200)

    assert html =~ "for families earning $110,000 or more"
    assert row(html, "Ithaca") =~ "$180,000"
    assert row(html, "No Price") =~ "$40,000"
  end

  test "an invalid income falls back to bracket 3", %{conn: conn} do
    for bad <- ["9", "abc", "0", ""] do
      html = conn |> get("/fields/rank?income=#{bad}&rank=best_value&count=10") |> html_response(200)
      assert html =~ "for families earning $48,000–75,000"
      assert html =~ ~s(<option selected value="3">)
      assert row(html, "Ithaca") =~ "$116,680"
    end
  end

  test "best value ranks by years of pay to cover the cost, without programs missing a net price", %{conn: conn} do
    html = conn |> get("/fields/rank?rank=best_value&count=10&income=3") |> html_response(200)

    assert html =~ "Best value: fewest years of pay to cover the cost"
    assert order(html) == ["Harvard", "Middle", "Ithaca"]
    refute html =~ "graduate school"
  end

  test "worst value reverses it and carries the graduate school note", %{conn: conn} do
    html = conn |> get("/fields/rank?rank=worst_value&count=10") |> html_response(200)

    assert order(html) == ["Ithaca", "Middle", "Harvard"]
    assert html =~ "Majors that lead to graduate school"
  end

  test "the graduate school note shows on the slowest repayment view only", %{conn: conn} do
    assert conn |> get("/fields/rank?rank=slowest_repay&count=10") |> html_response(200) =~ "Majors that lead to graduate school"
    refute conn |> get("/fields/rank") |> html_response(200) =~ "Majors that lead to graduate school"
  end

  test "months to repay stays the default ranking", %{conn: conn} do
    # 24,000 / (80,000 / 12) = 3.6; 10,000 / (30,000 / 12) = 4; 20,000 / (50,000 / 12) = 4.8; 24,000 / (40,000 / 12) = 7.2.
    assert conn |> get("/fields/rank") |> html_response(200) |> order() == ["Harvard", "Middle", "No Price", "Ithaca"]
  end

  test "an unknown count falls back to 100", %{conn: conn} do
    assert conn |> get("/fields/rank?count=abc") |> html_response(200) =~ ~s(<option selected value="100">)
  end
end
