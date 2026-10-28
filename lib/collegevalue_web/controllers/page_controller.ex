defmodule CollegevalueWeb.PageController do
  use CollegevalueWeb, :controller


  def index(conn, _params) do
    run_mode = if System.get_env("RELEASE_NAME"), do: "release", else: "mix"

    render(conn, "home.html",
      run_mode: run_mode,
      phoenix_ver: Application.spec(:phoenix, :vsn),
      elixir_ver: System.version(),
      noted_fields: Collegevalue.FieldNotes.approved_fields(),
      selectivity: Collegevalue.FieldNotes.selectivity(),
      page_title: "College Cost vs. Benefit by School and Major",
      meta_description:
        "Is college worth it? Compare the cost of every U.S. college and major against what graduates earn and owe, from the Department of Education's College Scorecard."
    )
  end

  def data(conn, _params) do
    run_mode = if System.get_env("RELEASE_NAME"), do: "release", else: "mix"

    render(conn, "data.html",
      run_mode: run_mode,
      phoenix_ver: Application.spec(:phoenix, :vsn),
      elixir_ver: System.version(),
      page_title: "About the Data",
      meta_description:
        "Where CollegeValue's numbers come from: the Department of Education's College Scorecard data, what it covers, where it has gaps, and how current it is."
    )
  end

  def up(conn, _params) do
    Ecto.Adapters.SQL.query!(Hello.Repo, "SELECT 1")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:ok, "")
  end
end
