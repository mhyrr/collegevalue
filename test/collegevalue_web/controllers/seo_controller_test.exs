defmodule CollegevalueWeb.SeoControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Repo
  alias Collegevalue.Colleges.College
  alias Collegevalue.Colleges.Discipline

  setup do
    with_data =
      Repo.insert!(%College{
        name: "Yale University",
        unitid: 130_794,
        city: "New Haven",
        state: "CT",
        zip: "06520",
        control: "2",
        yearly_cost: 85_120,
        debt_median: 11_648,
        earnings_median_after10: 100_533
      })

    without_data =
      Repo.insert!(%College{
        name: "Aarhus University",
        unitid: -1,
        city: "unknown city",
        state: "unknown state",
        zip: "unknown zip",
        control: "Foreign",
        accreditation: "NULL"
      })

    # `fields` is a view that rolls up bachelor's (credential level 3) disciplines.
    Repo.insert!(%Discipline{name: "Computer Science", credential_level: 3, pp_debt_mean: 33_795,
                             earnings_1yr: 65_959, college_id: with_data.id})
    Repo.insert!(%Discipline{name: "Air Force ROTC, Air Science and Operations", credential_level: 3,
                             pp_debt_mean: -1, earnings_1yr: -1, college_id: without_data.id})

    %{with_data: with_data, without_data: without_data}
  end

  describe "GET /sitemap.xml" do
    test "lists the listing pages and the colleges and fields with data", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      xml = response(conn, 200)

      assert response_content_type(conn, :xml)
      assert xml =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      assert xml =~ "/colleges/rank</loc>"
      assert xml =~ "/colleges/130794/Yale%20University</loc>"
      assert xml =~ "/fields/Computer%20Science</loc>"

      refute xml =~ "Aarhus"
      refute xml =~ "Air%20Force"
    end
  end

  describe "the college page head" do
    test "a college with data is indexable and titled with its place", %{conn: conn} do
      html = conn |> get("/colleges/130794/Yale%20University") |> html_response(200)

      assert html =~ "<title data-prefix=\"CV - \">CV - Yale University (New Haven, CT)</title>"
      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges/130794/Yale%20University">)
      refute html =~ "noindex"
    end

    test "a college with no data is noindex", %{conn: conn} do
      html = conn |> get("/colleges/-1/Aarhus%20University") |> html_response(200)

      assert html =~ ~s(<meta name="robots" content="noindex">)
    end
  end

  describe "canonical URLs" do
    test "drop sort and filter params", %{conn: conn} do
      html = conn |> get("/colleges/rank?rank=top_college_yearly_earnings&count=100") |> html_response(200)

      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges/rank">)
    end

    test "keep the page past the first, and give it its own title", %{conn: conn} do
      html = conn |> get("/colleges?page=2") |> html_response(200)
      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges?page=2">)
      assert html =~ "CV - All Colleges, 101–2"

      html = build_conn() |> get("/colleges?page=1") |> html_response(200)
      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges">)
    end
  end
end
