defmodule CollegevalueWeb.LayoutView do
  use CollegevalueWeb, :view

  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields.Field

  import CollegevalueWeb.Views.Helpers, only: [place: 1, field_short_name: 1, field_question: 1, cash: 1, no_data?: 1]

  @default_description "Is college worth it? Compare what every U.S. college and major costs with what its graduates earn and owe, from the Department of Education's College Scorecard."

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
  A path's URL on the site's public origin, for pages with no conn at hand
  (a LiveView's own template). Matches `canonical_url/1` for a page whose
  path is already canonical.
  """
  def page_url(path), do: (Application.get_env(:collegevalue, :canonical_url) || CollegevalueWeb.Endpoint.url()) <> path

  @doc """
  The page's meta description: an explicit `:meta_description` assign, one
  derived from the college or field the page shows, or the site default.
  """
  def meta_description(%{meta_description: description}) when is_binary(description),
    do: description

  def meta_description(%{college: %College{} = college}) do
    location = if place = place(college), do: " (#{place})", else: ""

    figures =
      [
        !no_data?(college.netprice_3) && "#{cash(college.netprice_3)} a year after aid for a $48–75k family",
        !no_data?(college.debt_median) && "#{cash(college.debt_median)} median debt",
        !no_data?(college.earnings_median_after10) && "#{cash(college.earnings_median_after10)} earned ten years out"
      ]
      |> Enum.filter(&is_binary/1)

    case figures do
      [] -> college_description(college.name <> location)
      figures -> "#{college.name}#{location}: #{Enum.join(figures, ", ")}. Debt and pay by major."
    end
  end

  def meta_description(%{field: %Field{name: name}, facts: %{earnings_median: earnings} = facts}) when is_number(earnings) do
    debt = if facts.debt_median, do: " and owe #{cash(facts.debt_median)}", else: ""

    "#{field_question(name)} Graduates earn a median #{cash(earnings)} their first year#{debt}. " <>
      "Compare #{facts.programs_with_earnings} bachelor's programs by debt and earnings, college by college."
  end

  def meta_description(%{field: %Field{name: name}}) do
    "#{field_short_name(name)}: how many colleges offer it, average debt at graduation and expected earnings " <>
      "one year after, with each college's program compared by debt and earnings."
  end

  def meta_description(_assigns), do: @default_description

  @doc """
  The page's schema.org JSON-LD, encoded for a `<script type="application/ld+json">`
  in the head, or nil. See `CollegevalueWeb.StructuredData`.
  """
  def json_ld(assigns, conn) do
    assigns
    |> CollegevalueWeb.StructuredData.graph(canonical_url(conn), origin(conn))
    |> CollegevalueWeb.StructuredData.encode()
  end

  @doc "The page title as it appears in search results and link previews."
  def full_title(assigns), do: (assigns[:page_title] || "College Cost vs. Benefit") <> " · CollegeValue"

  defp college_description(name_and_place) do
    "#{name_and_place}: yearly cost, tuition, median debt, completion rates " <>
      "and median earnings 6 to 10 years out, with debt and earnings by major, from College Scorecard data."
  end

end
