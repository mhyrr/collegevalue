defmodule CollegevalueWeb.SitemapController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Colleges, Fields}
  alias CollegevalueWeb.LayoutView

  # The listing pages. Search, results and the "for you" forms answer a
  # visitor's input and have no content of their own to index.
  @static_paths ["/", "/data", "/calculator", "/colleges", "/colleges/rank", "/fields", "/fields/rank"]

  @doc """
  Every page meant for the search index: the listing pages, the A to Z list's
  later pages, then each field and college with data behind it. Pages without
  data render noindex (see `Colleges.has_outcomes?/1` and
  `Fields.has_outcomes?/1`) and are left out.
  """
  def index(conn, _params) do
    page_paths =
      Enum.map(2..Colleges.college_page_count()//1, &Routes.college_path(conn, :index, page: &1))

    college_paths =
      Enum.map(Colleges.list_indexable_colleges(), fn {unitid, name} ->
        Routes.college_path(conn, :show, unitid, name)
      end)

    send_urlset(conn, @static_paths ++ page_paths ++ field_paths() ++ college_paths)
  end

  @doc """
  The listing pages and the field pages alone: the pages the keyword map
  targets, without the thousands of college pages. Search Console reports
  each sitemap's indexing on its own, so this one shows how the pages that
  matter are doing.
  """
  def fields(conn, _params), do: send_urlset(conn, @static_paths ++ field_paths())

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
