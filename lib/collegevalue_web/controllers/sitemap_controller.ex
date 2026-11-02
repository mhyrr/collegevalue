defmodule CollegevalueWeb.SitemapController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Colleges, Fields}
  alias CollegevalueWeb.LayoutView

  # The listing pages. Search, results and the "for you" forms answer a
  # visitor's input and have no content of their own to index.
  @static_paths ["/", "/data", "/calculator", "/colleges", "/colleges/rank", "/fields", "/fields/rank"]

  # One sitemap per kind of page, with no page in two of them, so Search
  # Console reports submitted vs. indexed for each template on its own.
  @sitemaps ["/sitemap-pages.xml", "/sitemap-fields.xml", "/sitemap-colleges.xml"]

  @doc """
  The sitemap index: the three sitemaps below. Pages with too little data
  render noindex (see `Colleges.indexable?/1` and `Fields.indexable?/1`) and
  are in none of them.
  """
  def index(conn, _params) do
    origin = LayoutView.origin(conn)

    body = [
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      Enum.map(@sitemaps, fn path -> ["  <sitemap><loc>", escape(origin <> path), "</loc></sitemap>\n"] end),
      "</sitemapindex>\n"
    ]

    send_xml(conn, body)
  end

  @doc "The listing pages, and the A to Z list's later pages."
  def pages(conn, _params) do
    page_paths = Enum.map(2..Colleges.college_page_count()//1, &Routes.college_path(conn, :index, page: &1))
    send_urlset(conn, @static_paths ++ page_paths)
  end

  @doc "Every field page open to the search index."
  def fields(conn, _params), do: send_urlset(conn, field_paths())

  @doc "Every college page open to the search index."
  def colleges(conn, _params) do
    college_paths =
      Colleges.list_indexable_colleges()
      |> Enum.map(fn {unitid, name} -> CollegevalueWeb.Views.Helpers.college_page_path(unitid, name) end)
      # Scorecard lists a few schools twice; both rows share a page.
      |> Enum.uniq()

    send_urlset(conn, college_paths)
  end

  defp field_paths do
    Enum.map(Fields.list_indexable_field_names(), &CollegevalueWeb.Views.Helpers.field_page_path/1)
  end

  defp send_urlset(conn, paths) do
    origin = LayoutView.origin(conn)

    body = [
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      Enum.map(paths, fn path -> ["  <url><loc>", escape(origin <> path), "</loc></url>\n"] end),
      "</urlset>\n"
    ]

    send_xml(conn, body)
  end

  defp send_xml(conn, body) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, body)
  end

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("'", "&apos;")
    |> String.replace("\"", "&quot;")
  end
end
