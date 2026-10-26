defmodule CollegevalueWeb.FieldYouControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Location.Zipcode

  setup do
    Repo.insert!(%Zipcode{zipcode: "20895", latitude: 39.03, longitude: -77.07})

    # {college, miles north of the zip, major, debt, earnings}; months = debt * 12 / earnings.
    for {college, north, major, debt, earnings} <- [
          {"Near Test", 0.1, "Economics", 10_000, 60_000},
          {"Near Test", 0.1, "Fine Arts", 24_000, 24_000},
          {"Near Test", 0.1, "History", -2, 40_000},
          {"Other Test", 0.2, "Biology", 20_000, 80_000},
          {"Far Test", 10.0, "Finance", 5_000, 90_000}
        ] do
      c = Repo.get_by(College, name: college) ||
            Repo.insert!(%College{name: college, unitid: System.unique_integer([:positive]),
                                  latitude: 39.03 + north, longitude: -77.07, sat_avg: 1200})

      Repo.insert!(%Discipline{name: major, credential_level: 3, earnings_1yr: earnings, stgp_debt_median: debt, college_id: c.id})
    end

    :ok
  end

  defp tbody(html), do: html |> String.split("<tbody") |> Enum.at(1)
  defp order(html), do: Regex.scan(~r/(Economics|Fine Arts|History|Biology|Finance)</, tbody(html)) |> Enum.map(&Enum.at(&1, 1))

  test "with no major picked, shows every major nearby, fastest to repay first", %{conn: conn} do
    html = conn |> get("/fields/you?zip=20895&distance=50&sat=") |> html_response(200)

    # Economics 2 months, Biology 3, Fine Arts 12; History has no debt figure; Finance is 690 miles away.
    assert order(html) == ["Economics", "Biology", "Fine Arts"]
    assert html =~ "No major picked"
  end

  test "picked majors show just those", %{conn: conn} do
    html = conn |> get("/fields/you?zip=20895&distance=50&sat=&major[]=Fine+Arts") |> html_response(200)

    assert order(html) == ["Fine Arts"]
    refute html =~ "No major picked"
  end

  test "an unknown zip says so instead of crashing", %{conn: conn} do
    html = conn |> get("/fields/you?zip=00000&distance=50&sat=") |> html_response(200)
    assert html =~ "Enter a valid zip!"
  end

  test "the page without a search shows no matches", %{conn: conn} do
    refute conn |> get("/fields/you") |> html_response(200) =~ "No major picked"
  end

  test "the rank page saves a picked income, and later visits start on it", %{conn: conn} do
    conn = get(conn, "/fields/rank?income=5")
    assert conn.resp_cookies["cv_income"].value == "5"

    html = build_conn() |> put_req_cookie("cv_income", "5") |> get("/fields/rank") |> html_response(200)
    assert html =~ "for families earning $110,000 or more"

    html = build_conn() |> put_req_cookie("cv_income", "5") |> get("/fields/rank?income=2") |> html_response(200)
    assert html =~ "for families earning $30,000–48,000"
  end

  test "a bad income cookie means bracket 3, and the search page passes the cookie on", %{conn: conn} do
    assert conn |> put_req_cookie("cv_income", "junk") |> get("/fields/rank") |> html_response(200) =~ "for families earning $48,000–75,000"

    html = build_conn() |> put_req_cookie("cv_income", "1") |> get("/fields/you?zip=20895&distance=50&sat=") |> html_response(200)
    assert html =~ "for families earning $0–30,000"
  end
end
