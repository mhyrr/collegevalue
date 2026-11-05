defmodule CollegevalueWeb.OpenDataControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}

  setup do
    yale =
      Repo.insert!(%College{
        name: "Yale University", unitid: 130_794, city: "New Haven", state: "CT", zip: "06520", control: "2",
        yearly_cost: 85_120, netprice_3: -2, debt_median: 11_648, earnings_median_after10: 100_533
      })

    for {name, debt, pay} <- [{"Computer Science", 33_795, 65_959}, {"Economics", 12_000, 72_000}, {"History", 18_000, 36_000}] do
      Repo.insert!(%Discipline{name: name, cipcode: 1107, credential_level: 3, stgp_debt_median: debt, earnings_1yr: pay, pp_debt_median: -2, college_id: yale.id})
    end

    # No data at all: left out of the programs file.
    Repo.insert!(%Discipline{name: "Physics", credential_level: 3, stgp_debt_median: -2, earnings_1yr: -1, college_id: yale.id})

    %{yale: yale}
  end

  describe "the bulk files" do
    test "the programs CSV has a header row and one row per program with data", %{conn: conn} do
      conn = get(conn, "/data/programs.csv")
      [header | rows] = conn |> response(200) |> String.split("\r\n", trim: true)

      assert response_content_type(conn, :csv)
      assert header == "unitid,college,state,major,cip_code,college_url,major_url,earnings_1yr,earnings_1yr_count,debt_median,months_to_repay,parent_plus_debt_median"
      assert length(rows) == 3
      assert Enum.find(rows, &(&1 =~ ",Economics,")) =~ ",72000,,12000,2.0,"
      refute Enum.any?(rows, &(&1 =~ "Physics"))
    end

    test "sentinels become empty values, never numbers", %{conn: conn} do
      json = conn |> get("/data/colleges.json") |> json_response(200)
      [yale] = json["rows"]

      assert yale["net_price_48_75k"] == nil
      assert yale["yearly_cost"] == 85_120
      assert yale["payoff_programs"] == 3
      assert json["license"] == "CC BY 4.0"
      assert json["columns"]["payoff_months"] =~ "months of first-year pay"
    end

    test "the majors file carries the verdict the page shows", %{conn: conn} do
      [cs] = conn |> get("/data/majors.json") |> json_response(200) |> Map.fetch!("rows") |> Enum.filter(&(&1["short_name"] == "Computer Science"))

      assert cs["months_to_repay"] == 6.1
      assert cs["verdict"] == "Usually, if you borrow the typical amount."
    end

    test "machine files stay out of the search index and open to any origin", %{conn: conn} do
      conn = get(conn, "/data/majors.csv")

      assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
      assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    end

    test "are gzipped when the client asks", %{conn: conn} do
      conn = conn |> put_req_header("accept-encoding", "gzip, br") |> get("/data/programs.csv")

      assert get_resp_header(conn, "content-encoding") == ["gzip"]
      assert :zlib.gunzip(conn.resp_body) =~ "Economics"
    end

    test "an unknown file is a 404", %{conn: conn} do
      assert conn |> get("/data/secrets.csv") |> response(404)
      assert build_conn() |> get("/data/majors.xml") |> response(404)
    end
  end

  describe "per-page JSON" do
    test "a college, with its programs", %{conn: conn} do
      json = conn |> get("/api/v1/colleges/130794") |> json_response(200)

      assert json["college"]["name"] == "Yale University"
      assert json["college"]["url"] == "http://localhost:4002/colleges/130794/yale-university"
      assert Enum.map(json["programs"], & &1["major"]) == ["Computer Science", "Economics", "History"]
    end

    test "a major, with its programs", %{conn: conn} do
      json = conn |> get("/api/v1/majors/computer-science") |> json_response(200)

      assert json["major"]["earnings_median"] == 65_959
      assert [%{"college" => "Yale University"}] = json["programs"]
    end

    test "is a JSON 404 for an unknown page", %{conn: conn} do
      assert conn |> get("/api/v1/colleges/999") |> json_response(404) == %{"error" => "not found"}
      assert build_conn() |> get("/api/v1/colleges/abc") |> json_response(404)
      assert build_conn() |> get("/api/v1/majors/no-such-major") |> json_response(404)
    end

    test "each page links its JSON", %{conn: conn} do
      assert conn |> get("/colleges/130794/yale-university") |> html_response(200) =~
               ~s(<link rel="alternate" type="application/json" href="http://localhost:4002/api/v1/colleges/130794">)

      assert build_conn() |> get("/fields/computer-science") |> html_response(200) =~
               ~s(<link rel="alternate" type="application/json" href="http://localhost:4002/api/v1/majors/computer-science">)
    end
  end

  test "llms.txt describes the measure, the files and every column", %{conn: conn} do
    text = conn |> get("/llms.txt") |> response(200)

    assert text =~ "# CollegeValue\n\n> "
    assert text =~ "http://localhost:4002/data/programs.csv"
    assert text =~ "- `parent_plus_debt_median`:"
    assert text =~ "CC BY 4.0"
  end
end
