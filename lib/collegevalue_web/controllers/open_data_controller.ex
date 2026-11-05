defmodule CollegevalueWeb.OpenDataController do
  @moduledoc """
  The open data: bulk files under /data, per-page JSON under /api/v1, and
  /llms.txt, the plain-text guide for language models and agents. The figures
  come from `CollegevalueWeb.OpenData`.

  Machine files carry `X-Robots-Tag: noindex`, so they don't compete with the
  pages in search; Google's Dataset Search finds them through the /data
  page's `Dataset` JSON-LD instead. Every response allows any origin, so a
  browser tool can read it directly.
  """
  use CollegevalueWeb, :controller

  alias CollegevalueWeb.{LayoutView, OpenData}
  alias Collegevalue.Scorecard

  @doc "/data/<dataset>.csv or .json."
  def download(conn, %{"file" => file}) do
    with [name, format] when format in ["csv", "json"] <- String.split(file, ".", parts: 2),
         true <- OpenData.dataset?(name) do
      {type, body} =
        case format do
          "csv" -> {"text/csv", OpenData.csv(name)}
          "json" -> {"application/json", Jason.encode!(OpenData.json(name, LayoutView.origin(conn)))}
        end

      conn
      |> put_resp_header("content-disposition", ~s(inline; filename="collegevalue-#{name}.#{format}"))
      |> send_machine(type, body)
    else
      _ -> conn |> put_status(:not_found) |> text("Not found. See #{LayoutView.origin(conn)}/llms.txt for the files.")
    end
  end

  @doc "/api/v1/majors/<slug>: one major and its programs."
  def major(conn, %{"slug" => slug}), do: send_json(conn, OpenData.major_json(slug, LayoutView.origin(conn)))

  @doc "/api/v1/colleges/<unitid>: one college and its bachelor's programs."
  def college(conn, %{"unitid" => unitid}) do
    case Integer.parse(unitid) do
      {id, ""} -> send_json(conn, OpenData.college_json(id, LayoutView.origin(conn)))
      _ -> send_json(conn, nil)
    end
  end

  @doc "/llms.txt (llmstxt.org): what the site holds, how it measures, and where the data is."
  def llms(conn, _params) do
    origin = LayoutView.origin(conn)

    send_machine(conn, "text/plain", llms_text(origin), index: true)
  end

  defp send_json(conn, nil), do: conn |> put_status(:not_found) |> send_machine("application/json", Jason.encode!(%{error: "not found"}))
  defp send_json(conn, data), do: send_machine(conn, "application/json", Jason.encode!(data))

  # Gzipped when the client takes it: the programs JSON is about 12 MB raw.
  defp send_machine(conn, type, body, opts \\ []) do
    conn =
      conn
      |> put_resp_content_type(type)
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> put_resp_header("vary", "accept-encoding")

    conn = if opts[:index], do: conn, else: put_resp_header(conn, "x-robots-tag", "noindex")

    if gzip?(conn) do
      conn |> put_resp_header("content-encoding", "gzip") |> send_resp(conn.status || 200, :zlib.gzip(body))
    else
      send_resp(conn, conn.status || 200, body)
    end
  end

  defp gzip?(conn), do: conn |> get_req_header("accept-encoding") |> Enum.any?(&String.contains?(&1, "gzip"))

  @doc false
  def llms_text(origin) do
    files =
      for name <- OpenData.datasets() do
        "- [#{OpenData.title(name)} (CSV)](#{origin}/data/#{name}.csv): also as [JSON](#{origin}/data/#{name}.json), with each column described."
      end

    columns =
      for name <- OpenData.datasets() do
        ["\n### #{name}\n\n", Enum.map(OpenData.columns(name), fn {key, text} -> "- `#{key}`: #{text}\n" end)]
      end

    """
    # CollegeValue

    > What every U.S. college and bachelor's major costs, what its graduates borrow, and what they earn, from the U.S. Department of Education's College Scorecard (#{Scorecard.release()} release). For each major and college, CollegeValue computes how many months of first-year pay the typical student debt equals, and answers "is it worth it?" from that.

    The main measure is months to repay: median federal student-loan debt × 12 ÷ median earnings one year after graduating. Lower is better. The typical major takes about 8 months; the common rule of thumb is to borrow no more than one year's pay (12 months). Earnings and debt cover students who received federal aid. Debt excludes Parent PLUS loans, which parents owe; the site reports those separately. One-year earnings understate majors that lead to graduate school or to careers that start slowly.

    Cite as: CollegeValue (#{origin}), from College Scorecard data. Our compiled data is #{OpenData.license().name} (#{OpenData.license().url}); the Scorecard data itself is a U.S. government work.

    ## Pages

    - [Majors ranked by months to repay](#{origin}/fields/rank): every bachelor's major, fastest to slowest.
    - [Best value colleges](#{origin}/colleges/rank): colleges ranked by ten-year earnings minus debt or cost.
    - [A major's page](#{origin}/fields/psychology): "Is a <major> degree worth it?", with a short answer, what changes the payback (public or private, selectivity, cost, parent loans) and every program by college. URL: /fields/<slug>.
    - [A college's page](#{origin}/colleges/131496/georgetown-university): cost by family income, debt, earnings, and payback for each of its majors. URL: /colleges/<unitid>/<slug>.
    - [About the data](#{origin}/data): sources, vintage and caveats.

    ## Data

    #{Enum.join(files, "\n")}
    - Per-page JSON: [#{origin}/api/v1/majors/<slug>](#{origin}/api/v1/majors/psychology) and [#{origin}/api/v1/colleges/<unitid>](#{origin}/api/v1/colleges/131496). Each page also links its JSON with `<link rel="alternate" type="application/json">`.

    ## Columns
    #{columns}
    ## Optional

    - [College Scorecard](#{Scorecard.url()}): the source data.
    """
  end
end
