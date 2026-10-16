defmodule CollegevalueWeb.LayoutView do
  use CollegevalueWeb, :view

  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields.Field

  import CollegevalueWeb.Views.Helpers, only: [place: 1]

  @default_description "Higher Ed 1 Dollar At A Time!  Should you go to college? What do you study? How much will it cost?."

  # Query params that select different content. The rest (sort, order,
  # show_all, rank, count) rearrange a page or come from a form, so their
  # variants point at the bare path.
  @canonical_params ["page"]

  @doc """
  The page's own URL on the site's public origin, for `<link rel="canonical">`.
  Only the params in `@canonical_params` stay in the query; page 1 has none.

  The origin is `config :collegevalue, :canonical_url` when set (production
  serves collegevalue.co while the endpoint's host is the fly.dev name), else
  the endpoint's URL.
  """
  def canonical_url(conn) do
    params =
      conn.query_string
      |> URI.decode_query()
      |> Map.take(@canonical_params)
      |> Enum.reject(fn {key, value} -> key == "page" and value in ["", "1"] end)

    query = if params == [], do: "", else: "?" <> URI.encode_query(params)
    origin(conn) <> conn.request_path <> query
  end

  @doc """
  The site's public origin, with no trailing slash: `config :collegevalue,
  :canonical_url` when set, else the endpoint's URL.
  """
  def origin(conn), do: Application.get_env(:collegevalue, :canonical_url) || Routes.url(conn)

  @doc """
  The page's meta description: an explicit `:meta_description` assign, one
  derived from the college or field the page shows, or the site default.
  """
  def meta_description(%{meta_description: description}) when is_binary(description),
    do: description

  def meta_description(%{college: %College{} = college}) do
    location = if place = place(college), do: " (#{place})", else: ""

    "#{college.name}#{location}: yearly cost, tuition, median debt, completion rates " <>
      "and median earnings 6 to 10 years out, with debt and earnings by major, from College Scorecard data."
  end

  def meta_description(%{field: %Field{name: name}}) do
    "#{name}: how many colleges offer it, average debt at graduation and expected earnings " <>
      "one year after, with each college's program compared by debt and earnings."
  end

  def meta_description(_assigns), do: @default_description

end
