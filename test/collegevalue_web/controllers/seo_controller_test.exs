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
    Repo.insert!(%Discipline{name: "Computer Science", credential_level: 3, stgp_debt_median: 33_795,
                             earnings_1yr: 65_959, college_id: with_data.id})
    Repo.insert!(%Discipline{name: "Air Force ROTC, Air Science and Operations", credential_level: 3,
                             stgp_debt_median: -2, earnings_1yr: -1, college_id: without_data.id})

    %{with_data: with_data, without_data: without_data}
  end

  describe "the sitemaps" do
    test "sitemap.xml is an index of the pages, fields and colleges sitemaps", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      xml = response(conn, 200)

      assert response_content_type(conn, :xml)
      assert xml =~ ~s(<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      for name <- ~w(pages fields colleges), do: assert(xml =~ "/sitemap-#{name}.xml</loc>")
    end

    test "each page is in one sitemap only", %{conn: conn} do
      pages = conn |> get("/sitemap-pages.xml") |> response(200)
      fields = build_conn() |> get("/sitemap-fields.xml") |> response(200)
      colleges = build_conn() |> get("/sitemap-colleges.xml") |> response(200)

      assert pages =~ "/colleges/rank</loc>"
      assert fields =~ "/fields/computer-science</loc>"
      assert colleges =~ "/colleges/130794/yale-university</loc>"

      refute pages =~ "/fields/computer-science<" or pages =~ "yale-university"
      refute fields =~ "/fields/rank<" or fields =~ "yale-university"
      refute colleges =~ "/colleges/rank<" or colleges =~ "/fields/"
    end

    test "pages without enough data are in none of them", %{conn: conn} do
      fields = conn |> get("/sitemap-fields.xml") |> response(200)
      colleges = build_conn() |> get("/sitemap-colleges.xml") |> response(200)

      refute fields =~ "air-force"
      refute colleges =~ "aarhus"
    end
  end

  describe "the home page" do
    test "links the majors with an approved note, never a draft", %{conn: conn} do
      root = Path.join(System.tmp_dir!(), "field_notes_#{System.unique_integer([:positive])}")
      Application.put_env(:collegevalue, :field_notes_root, root)
      on_exit(fn -> Application.delete_env(:collegevalue, :field_notes_root); File.rm_rf!(root) end)

      link = ~s(href="/fields/computer-science">Computer Science</a>)
      write = &Collegevalue.FieldNotes.write!("Computer Science", &1, &2)
      write.("facts.json", Jason.encode!(%{name: "Computer Science"}))

      write.("note.md", Collegevalue.FieldNotes.render_note([status: "draft"], "A note."))
      refute conn |> get("/") |> html_response(200) =~ link

      write.("note.md", Collegevalue.FieldNotes.render_note([status: "approved"], "A note."))
      assert build_conn() |> get("/") |> html_response(200) =~ link
    end

    test "says what the noted majors show about selective schools", %{conn: conn} do
      root = Path.join(System.tmp_dir!(), "field_notes_#{System.unique_integer([:positive])}")
      Application.put_env(:collegevalue, :field_notes_root, root)
      on_exit(fn -> Application.delete_env(:collegevalue, :field_notes_root); File.rm_rf!(root) end)

      band = fn name, pay, cost -> %{band: name, earnings_median: pay, four_year_cost_48_75k_median: cost} end
      facts = %{name: "Computer Science", short_name: "Computer Science",
                by_admission: [band.("under_10_percent", 130_000, 30_000), band.("25_to_60_percent", 70_000, 70_000),
                               band.("over_60_percent", 65_000, 60_000)]}
      Collegevalue.FieldNotes.write!("Computer Science", "facts.json", Jason.encode!(facts))
      Collegevalue.FieldNotes.write!("Computer Science", "note.md", Collegevalue.FieldNotes.render_note([status: "approved"], "A note."))

      html = conn |> get("/") |> html_response(200)
      assert html =~ "What 1 Majors Show"
      assert html =~ "earn a median 100% more in their first year"
      assert html =~ "pay 8% more, and in 1 of 1 majors"
      assert html =~ "typically pays $30,000 over four years, against $60,000"
      assert html =~ "College Scorecard</a>, #{Collegevalue.Scorecard.release()} release."
    end
  end

  describe "the college page head" do
    test "a college with data is indexable and titled with its place", %{conn: conn} do
      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)

      assert html =~ "<title data-suffix=\" · CollegeValue\">Yale University (New Haven, CT) · CollegeValue</title>"
      assert html =~ ~s(<link rel="canonical" href="http://localhost:4002/colleges/130794/yale-university">)
      refute html =~ "noindex"
    end

    test "a college with no data is noindex", %{conn: conn} do
      html = conn |> get("/colleges/-1/aarhus-university") |> html_response(200)

      assert html =~ ~s(<meta name="robots" content="noindex">)
    end
  end

  describe "the college page table" do
    setup %{with_data: yale} do
      program = fn name, debt, earnings ->
        Repo.insert!(%Discipline{name: name, credential_level: 3, stgp_debt_mean: debt, stgp_debt_median: debt,
                                 earnings_1yr: earnings, college_id: yale.id})
      end

      program.("Economics", 15_000, 70_000)
      program.("History", 16_000, -2)
      program.("Classics", -2, -1)
      :ok
    end

    test "lists the best-paid majors first and counts the ones with no data", %{conn: conn} do
      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)
      table = html |> String.split(~s(id="programs")) |> List.last()
      names = [">Economics<", ">Computer Science<", ">History<"]

      assert Enum.sort_by(names, &(:binary.match(table, &1) |> elem(0))) == names
      refute table =~ ">Classics<"
      assert table =~ "1 more program here reports no debt or earnings."
    end
  end

  describe "college URLs" do
    test "an old URL with the name moves permanently to the slug", %{conn: conn} do
      conn = get(conn, "/colleges/130794/Yale%20University")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/colleges/130794/yale-university"]
    end

    test "a stale slug moves to the college's own when its unitid is unique", %{conn: conn} do
      conn = get(conn, "/colleges/130794/yale")

      assert get_resp_header(conn, "location") == ["/colleges/130794/yale-university"]
    end

    test "colleges that share a unitid are told apart by slug", %{conn: conn} do
      Repo.insert!(%College{name: "Aalto University", unitid: -1, city: "Espoo", state: "unknown state", zip: "unknown zip"})

      assert conn |> get("/colleges/-1/aalto-university") |> html_response(200) =~ "Aalto University</h1>"
      assert_error_sent 404, fn -> get(build_conn(), "/colleges/-1/nowhere-university") end
    end

    test "a school listed twice gets one page, the row with outcomes", %{conn: conn, with_data: yale} do
      Repo.insert!(%College{name: "Yale-University", unitid: 130_794, city: "New Haven", state: "CT", zip: "06520"})

      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)
      assert html =~ "Yale University</h1>"
      assert yale.yearly_cost > 0
    end

    test "is a 404 for a unitid that doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn -> get(conn, "/colleges/999999/no-such-college") end
      assert_error_sent 404, fn -> get(build_conn(), "/colleges/abc/no-such-college") end
    end
  end

  describe "the parent loans ranking" do
    setup %{with_data: yale} do
      Repo.insert!(%Discipline{name: "Music", credential_level: 3, stgp_debt_median: 20_000, earnings_1yr: 24_000,
                               pp_debt_median: 60_000, pp_debt_count: 31, college_id: yale.id})
      Repo.insert!(%Discipline{name: "Economics", credential_level: 3, stgp_debt_median: 15_000, earnings_1yr: 70_000,
                               pp_debt_median: 30_000, pp_debt_count: 40, college_id: yale.id})
      :ok
    end

    test "lists the heaviest parent loans first, in months of pay, with no lightest-first view", %{conn: conn} do
      html = conn |> get("/fields/rank?rank=parent_loans") |> html_response(200)
      table = html |> String.split("rank-table") |> Enum.at(1)

      assert :binary.match(table, ">Music<") < :binary.match(table, ">Economics<")
      assert table =~ "30 months"
      assert table =~ "31 parents borrowed"
      assert html =~ "never added to the student's debt"
      assert html =~ ">Heaviest first</a>"
      refute html =~ ">Best first</a>"
    end
  end

  describe "which pages are open to the search index" do
    test "a college with outcomes but no bachelor's program reporting earnings is noindex and left out of the sitemap", %{conn: conn} do
      college = Repo.insert!(%College{name: "Beauty Academy", unitid: 555_001, city: "Mesa", state: "AZ", zip: "85201",
                                      yearly_cost: 20_000, debt_median: 8_000})
      Repo.insert!(%Discipline{name: "Cosmetology", credential_level: 1, stgp_debt_median: 9_000, earnings_1yr: 21_000, college_id: college.id})

      assert conn |> get("/colleges/555001/beauty-academy") |> html_response(200) =~ ~s(<meta name="robots" content="noindex">)
      refute build_conn() |> get("/sitemap-colleges.xml") |> response(200) =~ "beauty-academy"
    end
  end

  describe "the payoff summary on a college page" do
    test "leads with months to repay, years of pay and the fastest and slowest majors", %{conn: conn, with_data: yale} do
      for {name, debt, pay} <- [{"Economics", 12_000, 72_000}, {"History", 18_000, 36_000}, {"Physics", 15_000, 60_000}] do
        Repo.insert!(%Discipline{name: name, credential_level: 3, stgp_debt_median: debt, earnings_1yr: pay, college_id: yale.id})
      end

      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)

      # Months: 2.0 (Economics), 3.0 (Physics), 6.0 (History), 6.2 (Computer Science); median 4.5.
      assert html =~ "At Yale University, the typical bachelor&#39;s program takes 4.5 months of first-year pay to equal its graduates&#39; median student debt"
      assert html =~ "Fastest and Slowest to Repay"
      payoff = html |> String.split("payoff-majors") |> Enum.at(1)
      assert :binary.match(payoff, ">Economics<") < :binary.match(payoff, ">Computer Science<")
    end

    test "asks whether the college is worth it in the title, once it has a payoff", %{conn: conn, with_data: yale} do
      for {name, debt, pay} <- [{"Economics", 12_000, 72_000}, {"History", 18_000, 36_000}, {"Physics", 15_000, 60_000}] do
        Repo.insert!(%Discipline{name: name, credential_level: 3, stgp_debt_median: debt, earnings_1yr: pay, college_id: yale.id})
      end

      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)

      assert html =~ ">Is Yale University (New Haven, CT) Worth It? Debt and Pay by Major · CollegeValue</title>"
    end
  end

  describe "page metadata" do
    test "a field page's description answers its question with the data", %{conn: conn} do
      html = conn |> get("/fields/computer-science") |> html_response(200)

      assert html =~ ~s(<meta name="description" content="Is a Computer Science degree worth it? Graduates earn a median $65,959 their first year and owe $33,795.)
    end

    test "a college page's description leads with its figures", %{conn: conn} do
      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)

      assert html =~ ~s[content="Yale University (New Haven, CT): $11,648 median debt, $100,533 earned ten years out. Debt and pay by major."]
    end

    test "pages carry link-preview tags that match the title and canonical URL", %{conn: conn} do
      html = conn |> get("/fields/computer-science?sort_by=name&order=asc") |> html_response(200)

      assert html =~ ~s(<meta property="og:title" content="Is Computer Science Worth It? Debt vs. Earnings by College · CollegeValue">)
      assert html =~ ~s(<meta property="og:url" content="http://localhost:4002/fields/computer-science">)
    end

    test "sort links are nofollow, so crawlers skip the reordered copies", %{conn: conn} do
      html = conn |> get("/fields/computer-science") |> html_response(200)

      assert html =~ ~s(href="/fields/computer-science?sort_by=name&amp;order=desc" data-phx-link="patch" data-phx-link-state="push" rel="nofollow")
    end

    test "search results stay out of the index", %{conn: conn} do
      assert conn |> get("/results/yale") |> html_response(200) =~ ~s(<meta name="robots" content="noindex">)
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

      assert html =~ "How We Rank Colleges"
      assert html =~ "graduate within eight years"
      assert html =~ "Where the numbers come from"
    end

    test "the rank page switches measure and order by link, keeping the count", %{conn: conn} do
      html = conn |> get("/colleges/rank?rank=bottom_college_graddebt_to_earnings&count=250") |> html_response(200)

      assert html =~ ~s(aria-current="true" class="no-underline px-4 py-1.5 text-sm rounded-md bg-white shadow text-darkgreen font-bold">Graduates&#39; debt</a>)
      assert html =~ "Worst first: each college&#39;s median earnings ten years after students start, minus the median federal debt of students who graduated."
      assert html =~ ~s(href="/colleges/rank?count=250&amp;rank=top_college_graddebt_to_earnings")

      html = build_conn() |> get("/colleges/rank") |> html_response(200)
      assert html =~ "New Haven, CT"
    end

    test "the majors rank page switches measure by link and has no chart", %{conn: conn} do
      html = conn |> get("/fields/rank?rank=best_value") |> html_response(200)

      assert html =~ ~s(href="/fields/rank?rank=worst_value")
      assert html =~ ~s(href="/fields/rank?rank=top_earnings")
      assert html =~ "Best value: fewest years of pay to cover the cost"
      refute html =~ "What&#39;s Worth It?"
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
      html = conn |> get("/fields/computer-science") |> html_response(200)

      assert html =~ "Is a Computer Science degree worth it?"
      assert html =~ "the median pays its graduates $65,959 a year after graduation."
      assert html =~ "one year after graduating, for students who received federal aid"
    end

    test "leads with a short answer computed from payback months", %{conn: conn} do
      html = conn |> get("/fields/computer-science") |> html_response(200)

      assert html =~ "field-verdict"
      assert html =~ "Short answer"
      assert html =~ "of first-year pay at the median"
    end

    test "shows the note once it is approved, never as a draft", %{conn: conn} do
      root = Path.join(System.tmp_dir!(), "field_notes_#{System.unique_integer([:positive])}")
      Application.put_env(:collegevalue, :field_notes_root, root)
      on_exit(fn -> Application.delete_env(:collegevalue, :field_notes_root); File.rm_rf!(root) end)

      body = "The school matters as much as the major here, as at Yale University."
      write = &Collegevalue.FieldNotes.write!("Computer Science", "note.md",
                 Collegevalue.FieldNotes.render_note([status: &1], body))

      write.("draft")
      refute conn |> get("/fields/computer-science") |> html_response(200) =~ body

      write.("approved")
      html = build_conn() |> get("/fields/computer-science") |> html_response(200)
      assert html =~ "The school matters as much as the major here, as at "
      assert html =~ ~s(href="/colleges/130794/yale-university">Yale University</a>.)
    end

    test "has no answer when no program reports earnings", %{conn: conn} do
      html = conn |> get("/fields/air-force-rotc") |> html_response(200)

      refute html =~ "degree worth it?"
    end

    test "is a 404 for a field that doesn't exist", %{conn: conn} do
      assert_error_sent 404, fn -> get(conn, "/fields/no-such-field") end
    end

    test "links to itself by slug", %{conn: conn} do
      html = conn |> get("/fields/computer-science") |> html_response(200)

      assert html =~ ~s(href="/fields/computer-science?sort_by=name&amp;order=desc")
      refute html =~ "/fields/Computer%20Science"
    end
  end

  describe "the field page table" do
    setup %{with_data: yale} do
      college = fn name, unitid -> Repo.insert!(%College{name: name, unitid: unitid, city: "Town", state: "OH", zip: "44101"}) end
      program = fn college, debt, earnings ->
        Repo.insert!(%Discipline{name: "Psychology", credential_level: 3, stgp_debt_mean: debt, stgp_debt_median: debt,
                                 earnings_1yr: earnings, college_id: college.id})
      end

      program.(yale, 11_000, 52_000)
      program.(college.("Lower Pay College", 1), 20_000, 31_000)
      program.(college.("Suppressed College", 2), 18_000, -2)
      program.(college.("Empty College", 3), -2, -1)
      :ok
    end

    defp table_order(html, names), do: Enum.sort_by(names, &(:binary.match(html, &1) |> elem(0)))

    test "lists the best-paid programs first and the ones without earnings last", %{conn: conn} do
      html = conn |> get("/fields/psychology") |> html_response(200)
      names = ["Yale University", "Lower Pay College", "Suppressed College"]

      assert table_order(html, names) == names
    end

    test "keeps programs without earnings last when the sort is reversed", %{conn: conn} do
      html = conn |> get("/fields/psychology?sort_by=earnings&order=desc") |> html_response(200)
      names = ["Lower Pay College", "Yale University", "Suppressed College"]

      assert table_order(html, names) == names
    end

    test "counts the programs with no data instead of listing them", %{conn: conn} do
      html = conn |> get("/fields/psychology") |> html_response(200)

      refute html =~ "Empty College"
      assert html =~ "1 more school offers this major but reports no debt or earnings for it."
    end

    test "shows bachelor's programs until asked for every credential", %{conn: conn, with_data: yale} do
      Repo.insert!(%Discipline{name: "Psychology", credential_level: 5, stgp_debt_median: 30_000,
                               earnings_1yr: 60_000, college_id: yale.id})

      html = conn |> get("/fields/psychology") |> html_response(200)
      assert html =~ "Bachelor's <span class=\"font-normal text-gray-400 tabular-nums\">3</span>"
      refute html =~ "Master&#39;s Degree"

      html = build_conn() |> get("/fields/psychology?show_all=true") |> html_response(200)
      assert html =~ "Master&#39;s Degree"
    end
  end

  describe "old field URLs" do
    test "move to the slug for good, keeping the query", %{conn: conn} do
      conn = get(conn, "/fields/Computer%20Science?sort_by=name&order=asc")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/fields/computer-science?sort_by=name&order=asc"]
    end

    test "of a slug from before short names move to the short one", %{conn: conn} do
      conn = get(conn, "/fields/air-force-rotc-air-science-and-operations")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/fields/air-force-rotc"]
    end

    test "of a name that isn't a field are a 404, not a redirect", %{conn: conn} do
      assert_error_sent 404, fn -> get(conn, "/fields/No%20Such%20Field") end
    end

    test "leave the rank and you pages alone", %{conn: conn} do
      assert conn |> get("/fields/rank") |> html_response(200)
    end
  end

  describe "field short names and slugs" do
    alias Collegevalue.Fields

    test "come from the reviewed short name, else drop Scorecard's ', General'" do
      assert Fields.short_name("Accounting and Related Services") == "Accounting"
      assert Fields.short_name("Psychology, General") == "Psychology"
      assert Fields.short_name("Psychology, Other") == "Psychology (Other)"
      assert Fields.slug("Psychology, General") == "psychology"
      assert Fields.slug("Psychology, Other") == "psychology-other"
      assert Fields.slug("Teacher Education and Professional Development, Specific Levels and Methods") == "teacher-education"
    end

    test "keep the slugs that were already short" do
      assert Fields.slug("Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing") == "nursing"
      assert Fields.slug("Nursing") == "nursing-other"
      assert Fields.slug("Business Administration, Management and Operations") == "business"
      assert Fields.slug("English Language and Literature, General") == "english"
    end

    test "are one slug per field in the reviewed file, none a reserved path" do
      slugs =
        Path.join(:code.priv_dir(:collegevalue), "fields/short_names.json")
        |> File.read!()
        |> Jason.decode!()
        |> Map.keys()
        |> Enum.map(&Fields.slug/1)

      assert slugs -- Enum.uniq(slugs) == []
      refute Enum.any?(slugs, &(&1 in ["rank", "you", ""]))
    end

    test "head the page, with the Scorecard name beneath", %{conn: conn} do
      html = conn |> get("/fields/air-force-rotc") |> html_response(200)

      assert html =~ ~r{<h1[^>]*>Air Force ROTC</h1>}
      assert html =~ "College Scorecard field: Air Force ROTC, Air Science and Operations"
      assert html =~ ">Is Air Force ROTC Worth It?"
    end
  end

  # Answer engines quote a page that says where its numbers come from and when.
  describe "the source line" do
    test "names the Scorecard release and the page to cite on every data page", %{conn: conn} do
      release = Collegevalue.Scorecard.release()

      for {path, cite} <- [
            {"/fields/computer-science", "http://localhost:4002/fields/computer-science"},
            {"/colleges/130794/yale-university", "http://localhost:4002/colleges/130794/yale-university"},
            {"/colleges/rank?rank=bottom_college_debt", "http://localhost:4002/colleges/rank"},
            {"/fields/rank?rank=best_value", "http://localhost:4002/fields/rank"}
          ] do
        html = build_conn() |> get(path) |> html_response(200)

        assert html =~ "College Scorecard</a>, #{release} release. Updated #{Collegevalue.Scorecard.loaded()}.", path
        assert html =~ ~s(<span class="break-all">#{cite}</span>), path
      end

      html = conn |> get("/colleges/130794/yale-university") |> html_response(200)
      assert html =~ "Cite as: CollegeValue, “Yale University (New Haven, CT),”"
    end

    test "the data page states the same release", %{conn: conn} do
      assert conn |> get("/data") |> html_response(200) =~ "<strong>#{Collegevalue.Scorecard.release()}</strong>"
    end
  end

  describe "structured data" do
    # The page's one JSON-LD block, decoded.
    defp json_ld(html) do
      case Regex.scan(~r{<script type="application/ld\+json">(.*?)</script>}s, html) do
        [[_, json]] -> Jason.decode!(json)
        [] -> nil
      end
    end

    defp node(graph, type), do: Enum.find(graph["@graph"], &(&1["@type"] == type))

    test "a college page describes the college, with no website it doesn't list", %{conn: conn} do
      graph = conn |> get("/colleges/130794/yale-university") |> html_response(200) |> json_ld()

      assert node(graph, "CollegeOrUniversity") == %{
               "@type" => "CollegeOrUniversity",
               "name" => "Yale University",
               "url" => "http://localhost:4002/colleges/130794/yale-university",
               "address" => %{"@type" => "PostalAddress", "addressLocality" => "New Haven",
                              "addressRegion" => "CT", "addressCountry" => "US"}
             }

      assert [%{"name" => "Home"}, %{"name" => "Colleges", "item" => "http://localhost:4002/colleges"},
              %{"name" => "Yale University", "position" => 3}] = node(graph, "BreadcrumbList")["itemListElement"]
    end

    test "a college page names the college's website as sameAs", %{conn: conn, with_data: yale} do
      yale |> Ecto.Changeset.change(url: "www.yale.edu/") |> Repo.update!()
      graph = conn |> get("/colleges/130794/yale-university") |> html_response(200) |> json_ld()

      assert node(graph, "CollegeOrUniversity")["sameAs"] == "https://www.yale.edu/"
    end

    test "a noindex page carries none", %{conn: conn} do
      assert conn |> get("/colleges/-1/aarhus-university") |> html_response(200) |> json_ld() == nil
    end

    test "a field page gives the median first-year pay it shows", %{conn: conn} do
      graph = conn |> get("/fields/computer-science") |> html_response(200) |> json_ld()

      assert node(graph, "EducationalOccupationalProgram") == %{
               "@type" => "EducationalOccupationalProgram",
               "name" => "Computer Science (bachelor's degree)",
               "url" => "http://localhost:4002/fields/computer-science",
               "educationalCredentialAwarded" => "Bachelor's degree",
               "salaryUponCompletion" => %{
                 "@type" => "MonetaryAmountDistribution",
                 "name" => "Median earnings one year after graduation, across 1 bachelor's program",
                 "currency" => "USD",
                 "duration" => "P1Y",
                 "median" => 65_959
               }
             }

      assert node(graph, "BreadcrumbList")["itemListElement"] |> Enum.map(& &1["name"]) == ["Home", "Fields", "Computer Science"]
    end

    test "the data page describes the dataset and what it is based on", %{conn: conn} do
      dataset = conn |> get("/data") |> html_response(200) |> json_ld() |> node("Dataset")

      assert dataset["url"] == "http://localhost:4002/data"
      assert dataset["creator"]["name"] == "CollegeValue"
      assert dataset["isBasedOn"]["name"] == "College Scorecard"
      assert dataset["isBasedOn"]["datePublished"] == Collegevalue.Scorecard.release_date()
      assert String.length(dataset["description"]) >= 50
    end

    test "pages without a subject carry none", %{conn: conn} do
      assert conn |> get("/colleges/rank") |> html_response(200) |> json_ld() == nil
    end

    test "no value in the data can close the script tag" do
      json = CollegevalueWeb.StructuredData.encode(%{"name" => "</script><script>alert(1)</script><!--"})

      refute json =~ "<"
      assert Jason.decode!(json)["name"] == "</script><script>alert(1)</script><!--"
    end
  end
end
