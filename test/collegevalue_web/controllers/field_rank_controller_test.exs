defmodule CollegevalueWeb.FieldRankControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}

  setup do
    for {college, debt, earnings} <- [{"Slow College", 45_000, 15_000}, {"Quick College", 5_000, 40_000},
                                      {"Middle College", 24_000, 48_000}, {"Plus Only College", -2, 90_000}] do
      n = System.unique_integer([:positive])
      c = Repo.insert!(%College{name: college, unitid: n, debt_median: 99_000})

      Repo.insert!(%Discipline{name: "Economics", credential_level: 3, earnings_1yr: earnings,
                               stgp_debt_median: debt, pp_debt_median: 70_000, pp_debt_mean: 70_000, college_id: c.id})
    end

    :ok
  end

  defp order(html), do: Regex.scan(~r/(Quick|Middle|Slow|Plus Only) College/, html |> String.split("<tbody") |> List.last()) |> Enum.map(&Enum.at(&1, 1)) |> Enum.uniq()

  test "sorts by months to repay, fewest first, by default", %{conn: conn} do
    html = conn |> get("/fields/rank") |> html_response(200)

    assert html =~ "Months to Repay"
    refute html =~ "Difference"
    assert html =~ "gross pay"
    assert html =~ "only graduates who borrowed"
    # 5,000 / (40,000 / 12) = 1.5; 24,000 / (48,000 / 12) = 6; 45,000 / (15,000 / 12) = 36.
    assert html =~ "1.5 months"
    assert html =~ "6.0 months"
    assert html =~ "36 months"
    assert order(html) == ["Quick", "Middle", "Slow"]
  end

  test "slowest first, and the old debt-to-earnings key lands there too", %{conn: conn} do
    for key <- ["slowest_repay", "bottom_debt_to_earnings"] do
      html = conn |> get("/fields/rank?rank=#{key}&count=10") |> html_response(200)
      assert order(html) == ["Slow", "Middle", "Quick"]
    end
  end

  test "the earnings-only ranking keeps a program without debt, with no figure for it", %{conn: conn} do
    html = conn |> get("/fields/rank?rank=top_earnings&count=10") |> html_response(200)

    assert hd(order(html)) == "Plus Only"
    refute html =~ "$70,000"
    refute html =~ "$99,000"
  end
end
