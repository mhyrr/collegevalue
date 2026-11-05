defmodule CollegevalueWeb.OpenData do
  @moduledoc """
  CollegeValue's figures as open data: three datasets (majors, colleges and
  bachelor's programs), each served as CSV and JSON under /data, and per-page
  JSON under /api/v1. `columns/1` describes every column; the files, the API,
  /data and /llms.txt all read it, so they can't drift apart.

  Rows hold the same figures the pages print. Scorecard's missing-value
  sentinels (-1, -2, 0) become nil, never a number. The datasets only change
  with a Scorecard import, so outside tests each is built once per boot
  (`config :collegevalue, cache_open_data: false` turns that off).

  Our compiled data is CC BY 4.0: anyone may reuse it, citing CollegeValue.
  The underlying College Scorecard data is a U.S. government work.
  """

  import Ecto.Query
  alias Collegevalue.{Colleges, Fields, Repo, Scorecard}
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.FieldNotes.Facts
  alias CollegevalueWeb.{FieldAnswer, LayoutView}
  alias CollegevalueWeb.Views.Helpers

  @bachelors 3
  @datasets ~w(majors colleges programs)
  @license %{name: "CC BY 4.0", url: "https://creativecommons.org/licenses/by/4.0/"}

  @columns %{
    "majors" => [
      major: "The major's name, as College Scorecard lists it (CIP family).",
      short_name: "The name the site uses for it.",
      url: "The major's CollegeValue page.",
      programs_with_earnings: "Bachelor's programs in this major that report first-year earnings.",
      earnings_median: "Median, across those programs, of each program's median earnings one year after graduating (USD).",
      earnings_p25: "25th percentile of the same (USD).",
      earnings_p75: "75th percentile of the same (USD).",
      programs_with_debt: "Bachelor's programs in this major that report student debt.",
      debt_median: "Median, across those programs, of each program's median federal student-loan debt among graduates who borrowed (USD). Parent PLUS loans are not included.",
      months_to_repay: "Median debt × 12 ÷ earnings_median, counting only programs that report both: months of first-year pay the typical debt equals. The site's main measure.",
      rank: "Rank among majors on months_to_repay, 1 = least debt for the pay. Majors with fewer than 5 programs reporting both figures are unranked.",
      ranked_of: "How many majors are ranked.",
      verdict: "CollegeValue's short answer to \"is it worth it?\", from months_to_repay: under 6 months \"Usually, yes.\"; 6–9 \"Usually, if you borrow the typical amount.\"; 9–12 \"Usually, but it pays back slower than most majors.\"; over 12 \"Often not, on first-year pay alone.\""
    ],
    "colleges" => [
      unitid: "The college's Department of Education ID (IPEDS UNITID).",
      name: "The college's name.",
      city: "City.",
      state: "State or territory.",
      url: "The college's CollegeValue page.",
      control: "Public, private nonprofit or private for-profit.",
      admission_rate: "Share of applicants admitted (0 to 1).",
      sat_average: "Average SAT score of admitted students.",
      yearly_cost: "Sticker cost of attendance for one year, before aid (USD).",
      net_price_0_30k: "Average yearly net price after grants, for aided first-time full-time students from families earning $0–30,000 (USD).",
      net_price_48_75k: "The same, for families earning $48,000–75,000 (USD).",
      net_price_110k_plus: "The same, for families earning over $110,000 (USD).",
      debt_median: "Median federal student-loan debt of all borrowers, including students who left without a degree (USD).",
      earnings_10yr: "Median earnings ten years after starting, for students who received federal aid (USD).",
      completion_rate: "Share of first-time full-time students who finish within 8 years (0 to 1).",
      payoff_programs: "Bachelor's programs here that report both debt and first-year earnings.",
      payoff_months: "Median, across those programs, of months of first-year pay to equal the program's median student debt.",
      faster_than_percent: "Share of other colleges with at least 3 such programs whose median payoff_months is higher (slower)."
    ],
    "programs" => [
      unitid: "The college's Department of Education ID (IPEDS UNITID).",
      college: "The college's name.",
      state: "State or territory.",
      major: "The major's name, as College Scorecard lists it.",
      cip_code: "The major's 4-digit CIP code.",
      college_url: "The college's CollegeValue page.",
      major_url: "The major's CollegeValue page.",
      earnings_1yr: "Median earnings one year after graduating (USD).",
      earnings_1yr_count: "Graduates the earnings figure covers.",
      debt_median: "Median federal student-loan debt among graduates who borrowed (USD). Parent PLUS loans are not included.",
      months_to_repay: "debt_median × 12 ÷ earnings_1yr: months of first-year pay the debt equals.",
      parent_plus_debt_median: "Median Parent PLUS debt of parents who borrowed for graduates of this program (USD). Owed by the parents, not the student."
    ]
  }

  @titles %{
    "majors" => "Bachelor's majors: debt, first-year pay and payback",
    "colleges" => "Colleges: cost, debt, earnings and payback",
    "programs" => "Bachelor's programs, college by college"
  }

  def datasets, do: @datasets
  def dataset?(name), do: name in @datasets
  def title(name), do: Map.fetch!(@titles, name)
  def license, do: @license

  @doc "`[{column, description}]` for a dataset, in file order."
  def columns(name), do: Map.fetch!(@columns, name)

  @doc """
  A dataset as a file: `{content_type, gzipped_body}`. Rows stream from the
  database and are gzipped as they are encoded, so building the 29,000-row
  programs file never holds more than the finished gzip (about 1 MB) and
  one batch of rows. Holding every row and the 12 MB of JSON text at once ran
  a 512 MB machine out of memory (2026-11-05). Built once per boot.
  """
  def file(name, format) when name in @datasets and format in ["csv", "json"] do
    key = {__MODULE__, :file, name, format}

    if Application.get_env(:collegevalue, :cache_open_data, true) do
      case :persistent_term.get(key, nil) do
        nil -> tap(build_file(name, format), &:persistent_term.put(key, &1))
        file -> file
      end
    else
      build_file(name, format)
    end
  end

  defp build_file(name, format) do
    z = :zlib.open()
    # Window bits 31: a gzip wrapper, which browsers and curl accept as is.
    :ok = :zlib.deflateInit(z, :default, :deflated, 31, 8, :default)

    try do
      chunks = with_rows(name, fn rows -> rows |> encode(name, format) |> Enum.map(&:zlib.deflate(z, &1)) end)
      {content_type(format), IO.iodata_to_binary([chunks, :zlib.deflate(z, [], :finish)])}
    after
      :zlib.close(z)
    end
  end

  defp content_type("csv"), do: "text/csv"
  defp content_type("json"), do: "application/json"

  defp encode(rows, name, "csv"), do: CSV.encode(rows, headers: name |> columns() |> Keyword.keys())

  # The envelope, then the rows one at a time: `{..., "rows": [row, row]}`.
  defp encode(rows, name, "json") do
    head = envelope(LayoutView.page_url(""), title(name), columns(name)) |> Jason.encode!() |> String.trim_trailing("}")

    Stream.concat([
      [head, ~s(,"rows":[)],
      rows |> Stream.map(&Jason.encode_to_iodata!/1) |> Stream.intersperse(","),
      ["]}"]
    ])
  end

  # Calls `fun` with the dataset's rows as a stream. The big queries stream
  # inside a transaction, 500 rows at a time.
  defp with_rows("majors", fun) do
    ranking = Facts.ranking()
    Fields.list_indexable_field_names() |> Stream.map(&major_row(&1, ranking)) |> Stream.reject(&is_nil/1) |> fun.()
  end

  defp with_rows("colleges", fun) do
    indexable = MapSet.new(Colleges.list_indexable_colleges())

    # Scorecard lists a few schools twice; the row with outcomes wins, as on
    # the page (`Colleges.find_college_page/2`).
    query = from(c in College, where: c.unitid > 0, order_by: [asc: c.name, desc_nulls_last: c.earnings_median_after10])

    stream(query, fn colleges ->
      colleges
      |> Stream.filter(&MapSet.member?(indexable, {&1.unitid, &1.name}))
      |> Stream.uniq_by(& &1.unitid)
      |> Stream.map(&college_row/1)
      |> fun.()
    end)
  end

  defp with_rows("programs", fun) do
    query = programs_query() |> order_by([d, c], asc: c.name, asc: d.name)
    stream(query, &(&1 |> Stream.map(fn p -> program_row(p) end) |> fun.()))
  end

  defp stream(query, fun) do
    {:ok, result} = Repo.transaction(fn -> query |> Repo.stream(max_rows: 500) |> fun.() end, timeout: :infinity)
    result
  end

  @doc "One major's page as JSON: its row and its programs. nil for no such major."
  def major_json(slug, origin) do
    with {:ok, name} <- Fields.resolve_field_segment(slug),
         row when row != nil <- major_row(name, Facts.ranking()) do
      programs = programs_query() |> where([d], d.name == ^name) |> order_by([d, c], asc: c.name) |> Repo.all() |> Enum.map(&program_row/1)
      Map.merge(envelope(origin, row.short_name, columns("majors")), %{major: row, programs: programs, program_columns: Map.new(columns("programs"))})
    else
      _ -> nil
    end
  end

  @doc "One college's page as JSON: its row and its bachelor's programs. nil for no such college."
  def college_json(unitid, origin) do
    case Repo.one(from c in College, where: c.unitid == ^unitid and c.unitid > 0, limit: 1, order_by: [desc: c.earnings_median_after10]) do
      nil ->
        nil

      college ->
        programs = programs_query() |> where([d, c], c.id == ^college.id) |> order_by([d], asc: d.name) |> Repo.all() |> Enum.map(&program_row/1)
        Map.merge(envelope(origin, college.name, columns("colleges")), %{college: college_row(college), programs: programs, program_columns: Map.new(columns("programs"))})
    end
  end

  defp envelope(origin, title, columns) do
    %{
      title: title,
      publisher: "CollegeValue",
      publisher_url: origin <> "/",
      source: "U.S. Department of Education, College Scorecard, #{Scorecard.release()} release",
      source_url: Scorecard.url(),
      license: @license.name,
      license_url: @license.url,
      cite_as: "CollegeValue (#{origin}), from College Scorecard data",
      columns: Map.new(columns)
    }
  end

  defp major_row(name, ranking) do
    stats =
      Repo.one(
        from d in Discipline,
          join: c in College,
          on: c.id == d.college_id,
          # As on the page: unitid -1 marks a college with no federal ID.
          where: d.name == ^name and d.credential_level == @bachelors and c.unitid > 0,
          select: %{
            with_earnings: fragment("count(*) filter (where ? > 0)", d.earnings_1yr),
            with_debt: fragment("count(*) filter (where ? > 0)", d.stgp_debt_median),
            e50: fragment("percentile_cont(0.5) within group (order by ?) filter (where ? > 0)", d.earnings_1yr, d.earnings_1yr),
            e25: fragment("percentile_cont(0.25) within group (order by ?) filter (where ? > 0)", d.earnings_1yr, d.earnings_1yr),
            e75: fragment("percentile_cont(0.75) within group (order by ?) filter (where ? > 0)", d.earnings_1yr, d.earnings_1yr),
            d50: fragment("percentile_cont(0.5) within group (order by ?) filter (where ? > 0)", d.stgp_debt_median, d.stgp_debt_median),
            # Payback compares like with like: debt only of programs that
            # also report earnings, as the page's facts do.
            paired_d50:
              fragment("percentile_cont(0.5) within group (order by ?) filter (where ? > 0 and ? > 0)", d.stgp_debt_median, d.stgp_debt_median, d.earnings_1yr)
          }
      )

    if stats.with_earnings > 0 do
      months = if stats.paired_d50, do: Float.round(stats.paired_d50 * 12 / stats.e50, 1)
      index = Enum.find_index(ranking.ranked, fn {n, _} -> n == name end)
      verdict = months && FieldAnswer.verdict(%{months_to_repay: %{of_major: months, programs: 0, p25: nil, p75: nil}})

      %{
        major: name,
        short_name: Fields.short_name(name),
        url: LayoutView.page_url(Helpers.field_page_path(name)),
        programs_with_earnings: stats.with_earnings,
        earnings_median: round_or_nil(stats.e50),
        earnings_p25: round_or_nil(stats.e25),
        earnings_p75: round_or_nil(stats.e75),
        programs_with_debt: stats.with_debt,
        debt_median: round_or_nil(stats.d50),
        months_to_repay: months,
        rank: index && index + 1,
        ranked_of: length(ranking.ranked),
        verdict: verdict && verdict.headline
      }
    end
  end

  defp college_row(%College{} = c) do
    payoff = Fields.college_payoff(c.id)

    %{
      unitid: c.unitid,
      name: c.name,
      city: c.city,
      state: c.state,
      url: LayoutView.page_url(Helpers.college_page_path(c.unitid, c.name)),
      control: if(is_binary(c.control), do: Helpers.control(c.control)),
      admission_rate: present(c.admissions_rate),
      sat_average: present(c.sat_avg),
      yearly_cost: present(c.yearly_cost),
      net_price_0_30k: present(c.netprice_1),
      net_price_48_75k: present(c.netprice_3),
      net_price_110k_plus: present(c.netprice_5),
      debt_median: present(c.debt_median),
      earnings_10yr: present(c.earnings_median_after10),
      completion_rate: present(c.fouryear_200_completion),
      payoff_programs: payoff && payoff.programs,
      payoff_months: payoff && Float.round(payoff.months * 1.0, 1),
      faster_than_percent: payoff && payoff.faster_than
    }
  end

  defp programs_query do
    from d in Discipline,
      join: c in College,
      on: c.id == d.college_id,
      where: d.credential_level == @bachelors and c.unitid > 0 and (d.earnings_1yr > 0 or d.stgp_debt_median > 0),
      select: %{
        unitid: c.unitid,
        college: c.name,
        state: c.state,
        major: d.name,
        cip_code: d.cipcode,
        earnings_1yr: d.earnings_1yr,
        earnings_1yr_count: d.earnings_1yr_count,
        debt_median: d.stgp_debt_median,
        parent_plus_debt_median: d.pp_debt_median
      }
  end

  defp program_row(p) do
    earnings = present(p.earnings_1yr)
    debt = present(p.debt_median)

    %{
      unitid: p.unitid,
      college: p.college,
      state: p.state,
      major: p.major,
      cip_code: present(p.cip_code),
      college_url: LayoutView.page_url(Helpers.college_page_path(p.unitid, p.college)),
      major_url: LayoutView.page_url(Helpers.field_page_path(p.major)),
      earnings_1yr: earnings,
      earnings_1yr_count: earnings && present(p.earnings_1yr_count),
      debt_median: debt,
      months_to_repay: if(earnings && debt, do: Float.round(debt * 12 / earnings, 1)),
      parent_plus_debt_median: present(p.parent_plus_debt_median)
    }
  end

  # Scorecard marks missing values -1, -2 or 0; none of them is a number.
  defp present(value) when is_number(value) and value > 0, do: value
  defp present(_value), do: nil

  defp round_or_nil(nil), do: nil
  defp round_or_nil(value), do: round(value)
end
