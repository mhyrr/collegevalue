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

      assert html =~ "<title data-suffix=\" · CollegeValue\">Yale University (New Haven, CT) · CollegeValue</title>"
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
      assert html =~ "All Colleges, 101–2"

      html = build_conn() |> get("/colleges?page=1") |> html_response(200)
      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges">)
    end
  end

  # Google reads the first, static render, so each method section must be in it.
  describe "keyword-map pages explain their method" do
    test "the rank page says how it ranks and where the data comes from", %{conn: conn} do
      html = conn |> get("/colleges/rank") |> html_response(200)

      assert html =~ "How we rank colleges"
      assert html =~ "graduation rate"
      assert html =~ "Where the numbers come from"
    end

    test "the calculator says how it computes degree ROI", %{conn: conn} do
      html = conn |> get("/calculator") |> html_response(200)

      assert html =~ "<title data-suffix=\" · CollegeValue\">College ROI Calculator: Degree Cost vs. Earnings · CollegeValue</title>"
      assert html =~ "How the degree ROI calculator works"
      assert html =~ "Earnings vs. cost."
    end
  end

  describe "the field page" do
    test "answers whether the degree is worth it, from the data", %{conn: conn} do
      html = conn |> get("/fields/Computer%20Science") |> html_response(200)

      assert html =~ "Is a Computer Science degree worth it?"
      assert html =~ "the median pays its graduates $65,959 a year after graduation."
      assert html =~ "one year after graduating, for students who received federal aid"
    end

    test "shows the note once it is approved, never as a draft", %{conn: conn} do
      root = Path.join(System.tmp_dir!(), "field_notes_#{System.unique_integer([:positive])}")
      Application.put_env(:collegevalue, :field_notes_root, root)
      on_exit(fn -> Application.delete_env(:collegevalue, :field_notes_root); File.rm_rf!(root) end)

      body = "The school matters as much as the major here."
      write = &Collegevalue.FieldNotes.write!("Computer Science", "note.md",
                 Collegevalue.FieldNotes.render_note([status: &1], body))

      write.("draft")
      refute conn |> get("/fields/Computer%20Science") |> html_response(200) =~ body

      write.("approved")
      assert build_conn() |> get("/fields/Computer%20Science") |> html_response(200) =~ body
    end

    test "has no answer when no program reports earnings", %{conn: conn} do
      html = conn |> get("/fields/Air%20Force%20ROTC%2C%20Air%20Science%20and%20Operations") |> html_response(200)

      refute html =~ "degree worth it?"
    end

    test "is a 404 for a field that doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn -> get(conn, "/fields/No%20Such%20Field") end
    end
  end
end
