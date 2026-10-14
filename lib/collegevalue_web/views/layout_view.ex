defmodule CollegevalueWeb.LayoutView do
  use CollegevalueWeb, :view

  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields.Field

  @default_description "Higher Ed 1 Dollar At A Time!  Should you go to college? What do you study? How much will it cost?."

  @doc """
  The page's own URL on the site's public origin, for `<link rel="canonical">`.

  The origin is `config :collegevalue, :canonical_url` when set (production
  serves collegevalue.co while the endpoint's host is the fly.dev name), else
  the endpoint's URL.
  """
  def canonical_url(conn) do
    origin = Application.get_env(:collegevalue, :canonical_url) || Routes.url(conn)
    query = if conn.query_string == "", do: "", else: "?" <> conn.query_string
    origin <> conn.request_path <> query
  end

  @doc """
  The page's meta description: an explicit `:meta_description` assign, one
  derived from the college or field the page shows, or the site default.
  """
  def meta_description(%{meta_description: description}) when is_binary(description),
    do: description

  def meta_description(%{college: %College{} = college}) do
    "#{college.name}#{location(college)}: yearly cost, tuition, median debt, completion rates " <>
      "and median earnings 6 to 10 years out, with debt and earnings by major, from College Scorecard data."
  end

  def meta_description(%{field: %Field{name: name}}) do
    "#{name}: how many colleges offer it, average debt at graduation and expected earnings " <>
      "one year after, with each college's program compared by debt and earnings."
  end

  def meta_description(_assigns), do: @default_description

  defp location(%College{city: city, state: state})
       when is_binary(city) and city not in ["", "city", "unknown city"] and is_binary(state) do
    if state =~ ~r/^[A-Z]{2}$/, do: " (#{city}, #{state})", else: ""
  end

  defp location(_college), do: ""
end
