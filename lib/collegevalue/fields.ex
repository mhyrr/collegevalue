defmodule Collegevalue.Fields do
  @moduledoc """
  The Fields context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Fields.{Field, Rank}
  alias Collegevalue.Repo

  # College Scorecard reports net price (NPT4) in five family-income brackets:
  # 1: $0-30k, 2: $30-48k, 3: $48-75k, 4: $75-110k, 5: $110k+.
  @net_price_columns %{1 => :netprice_1, 2 => :netprice_2, 3 => :netprice_3, 4 => :netprice_4, 5 => :netprice_5}
  @default_income_bracket 3
  @years_of_study 4

  def list_fields do

    Repo.all(Field)

    # This needs to be another schema/view

    # Dump this into an ets table later
    # Another select d.debt_mean, d.earnings, c.name, d.credential_level  from disciplines d, colleges c where d.college_id = c.id and d.name = 'Business/Commerce, General.' order by earnings DESC;

  end

  def list_fields(col, order) when is_binary(col) and is_binary(order) do

    sort = String.to_atom(col)
    sort_order = String.to_existing_atom(order)

    Field
    |> order_by({^sort_order, ^sort} )
    |> Repo.all()

  end

  def match_fields_by_name(name) do

    like = "%#{name}%"

    query = from f in Field,
      where: ilike(f.name, ^like),
      select: f.name,
      limit: 10
    Repo.all(query)

  end

  def match_fields(name) do

    like = "%#{name}%"

    query = from f in Field,
      where: ilike(f.name, ^like),
      order_by: [{:asc, :name}]
    Repo.all(query)

  end

  def get_field!(name), do: Repo.get_by!(Field, name: name)

  # Short names, reviewed by hand: what a student searches, not Scorecard's
  # CIP title. A field missing from the file gets `default_short_name/1`.
  # The short name makes the slug, and a slug is permanent once live:
  # renaming one means another redirect.
  @short_names_path Path.expand("../../priv/fields/short_names.json", __DIR__)
  @external_resource @short_names_path
  @short_names @short_names_path |> File.read!() |> Jason.decode!()

  # The slugs that were live from 2026-10-23 to the short names. Kept so
  # those URLs 301 to the new ones.
  @legacy_slugs %{
    "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing" => "nursing",
    "Nursing" => "nursing-other",
    "Business Administration, Management and Operations" => "business",
    "English Language and Literature, General" => "english"
  }

  @doc """
  The name the site shows for a field: "Nursing" for Scorecard's
  "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing".
  """
  def short_name(name), do: Map.get_lazy(@short_names, name, fn -> default_short_name(name) end)

  defp default_short_name(name) do
    name
    |> String.replace(~r/,\s*General\.?$/, "")
    |> String.replace(~r/,\s*Other$/, " (Other)")
  end

  @doc """
  The field's URL segment: its short name in lowercase words joined by hyphens.

      iex> Collegevalue.Fields.slug("Psychology, General")
      "psychology"
  """
  def slug(name), do: slugify(short_name(name))

  @doc "The slug a field had before short names, which now redirects."
  def legacy_slug(name) do
    Map.get_lazy(@legacy_slugs, name, fn -> name |> String.replace(~r/,\s*General\.?$/, "") |> slugify() end)
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  @doc """
  What a `/fields/<segment>` URL points at: `{:ok, name}` for a current slug,
  `{:moved, slug}` for an old name URL or a legacy slug, `:error` for neither.
  `segment` is decoded.
  """
  def resolve_field_segment(segment) do
    names = Field |> select([f], f.name) |> Repo.all()

    cond do
      name = Enum.find(names, &(slug(&1) == segment)) -> {:ok, name}
      name = Enum.find(names, &(&1 == segment or legacy_slug(&1) == segment)) -> {:moved, slug(name)}
      true -> :error
    end
  end

  @doc "The field whose `slug/1` is `slug`. Raises `Ecto.NoResultsError` (a 404) when none is."
  def get_field_by_slug!(slug) do
    case resolve_field_segment(slug) do
      {:ok, name} -> get_field!(name)
      _ -> raise Ecto.NoResultsError, queryable: Field
    end
  end

  @doc """
  Whether any college reports debt or earnings for the field. A field without
  either has a page with nothing on it but a list of names, so it stays out of
  the search index and the sitemap.
  """
  def has_outcomes?(%Field{debt_avg: debt, earn_avg: earn}), do: positive?(debt) or positive?(earn)

  @doc """
  The name of every field that `has_outcomes?/1`, ordered by name.
  """
  def list_indexable_field_names do
    Field
    |> where([f], f.debt_avg > 0 or f.earn_avg > 0)
    |> order_by(asc: :name)
    |> select([f], f.name)
    |> Repo.all()
  end

  defp positive?(%Decimal{} = value), do: Decimal.gt?(value, 0)
  defp positive?(value) when is_number(value), do: value > 0
  defp positive?(_value), do: false

  @doc """
  Bachelor's programs ranked by first-year earnings alone, highest first for
  `"top"`. A program's debt is its own median federal student-loan debt
  (`stgp_debt_median`), never the college's: a program without one shows no
  debt. `require_debt: true` keeps only programs that report it; `income:`
  picks the family-income bracket for the cost columns.
  """
  def get_bachelors_earnings(sort \\ "top", limit \\ 100, opts \\ []) do
    direction = if sort == "top", do: :desc, else: :asc

    query =
      bachelors_ranks(Keyword.get(opts, :income, @default_income_bracket))
      |> order_by([_c, d], [{^direction, d.earnings_1yr}, {:asc, d.id}])
      |> limit(^limit)

    query =
      if Keyword.get(opts, :require_debt, false),
        do: where(query, [_c, d], d.stgp_debt_median > 0),
        else: query

    Repo.all(query)
  end

  @doc """
  Bachelor's programs ranked by months to repay: the program's median
  federal student-loan debt over one month of its median first-year
  earnings. `"fastest"` puts the fewest months first, `"slowest"` the most.
  Only programs that report both figures are ranked: a missing debt is never
  filled in with the college's. `income` picks the family-income bracket for
  the cost columns.
  """
  def get_bachelors_months_to_repay(sort \\ "fastest", limit \\ 100, income \\ @default_income_bracket) do
    direction = if sort == "slowest", do: :desc, else: :asc

    bachelors_ranks(income)
    |> where([_c, d], d.stgp_debt_median > 0)
    |> order_by([_c, d], [{^direction, fragment("?::float * 12 / ?", d.stgp_debt_median, d.earnings_1yr)}, {:asc, d.id}])
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Bachelor's programs ranked by value: years of first-year pay it takes to
  equal four years of the school's net price for the family-income bracket.
  `"best"` puts the fewest years first, `"worst"` the most. Only programs
  whose school reports a net price for the bracket are ranked.
  """
  def get_bachelors_value(sort \\ "best", limit \\ 100, income \\ @default_income_bracket) do
    direction = if sort == "worst", do: :desc, else: :asc
    column = net_price_column(income)

    bachelors_ranks(income)
    |> where([c, _d], field(c, ^column) > 0)
    |> order_by([c, d], [
      {^direction, fragment("?::float * ? / ?", field(c, ^column), type(^@years_of_study, :integer), d.earnings_1yr)},
      {:asc, d.id}
    ])
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Months of first-year pay it takes to equal the debt:
  `debt / (earnings_1yr / 12)`. nil unless both are positive. Gross pay, so
  it is a floor on how long repayment really takes. The SQL in
  `bachelors_ranks/0` computes the same figure so rankings can sort on it.
  """
  def months_to_repay(debt, earnings_1yr)
      when is_number(debt) and is_number(earnings_1yr) and debt > 0 and earnings_1yr > 0,
      do: debt * 12 / earnings_1yr

  def months_to_repay(_debt, _earnings_1yr), do: nil

  @doc "The family-income brackets, 1 to 5."
  def income_brackets, do: @net_price_columns |> Map.keys() |> Enum.sort()

  def default_income_bracket, do: @default_income_bracket

  @doc "Years of study the cost figures assume."
  def years_of_study, do: @years_of_study

  @doc """
  The income bracket for a URL value ("1" to "5"); anything else falls back
  to the default bracket, 3.
  """
  def income_bracket(bracket) when is_map_key(@net_price_columns, bracket), do: bracket

  def income_bracket(value) when is_binary(value) do
    case Integer.parse(value) do
      {bracket, ""} -> income_bracket(bracket)
      _ -> @default_income_bracket
    end
  end

  def income_bracket(_value), do: @default_income_bracket

  defp net_price_column(bracket), do: Map.fetch!(@net_price_columns, income_bracket(bracket))

  @doc """
  A college's yearly net price after grants for the income bracket, or nil
  when it isn't reported (stored as -2, -1 or 0).
  """
  def net_price(%College{} = college, bracket) do
    case Map.get(college, net_price_column(bracket)) do
      price when is_number(price) and price > 0 -> price
      _ -> nil
    end
  end

  @doc "Four years of a yearly cost, or nil unless the cost is positive."
  def four_year_cost(yearly) when is_number(yearly) and yearly > 0, do: yearly * @years_of_study
  def four_year_cost(_yearly), do: nil

  @doc """
  What four years of net price leaves after the program's median federal
  student-loan debt: what a family covers from savings, work, Parent PLUS or
  private loans. Never below 0; nil unless both figures are positive.
  """
  def gap_after_loans(yearly_net_price, debt) when is_number(debt) and debt > 0 do
    case four_year_cost(yearly_net_price) do
      nil -> nil
      cost -> max(0, cost - debt)
    end
  end

  def gap_after_loans(_yearly_net_price, _debt), do: nil

  @doc """
  Years of first-year pay it takes to equal four years of net price, or nil
  unless both are positive. `get_bachelors_value/3` sorts on the same figure.
  """
  def value_years(yearly_net_price, earnings_1yr)
      when is_number(yearly_net_price) and is_number(earnings_1yr) and yearly_net_price > 0 and earnings_1yr > 0,
      do: yearly_net_price * @years_of_study / earnings_1yr

  def value_years(_yearly_net_price, _earnings_1yr), do: nil

  # Parent PLUS medians above this many months of first-year pay get a
  # warning beside the student figure.
  @parent_plus_warning_months 24

  @doc "Months of first-year pay above which a Parent PLUS median is flagged."
  def parent_plus_warning_months, do: @parent_plus_warning_months

  @doc """
  Months of first-year pay it takes to equal the program's Parent PLUS
  median, when that median is past `parent_plus_warning_months/0`; nil
  otherwise. Parent PLUS is a median over parents who borrowed, so it is
  shown beside the student figure and never added to it.
  """
  def parent_plus_warning(parent_debt, earnings_1yr) do
    case months_to_repay(parent_debt, earnings_1yr) do
      months when is_number(months) and months > @parent_plus_warning_months -> months
      _ -> nil
    end
  end

  # Every bachelor's program that reports first-year earnings, as a `Rank`,
  # with its school's net price for the income bracket. Missing Scorecard
  # figures are stored as -1 or -2, so a figure that isn't positive is nil.
  defp bachelors_ranks(income) do
    column = net_price_column(income)

    from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr > 0,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: fragment("NULLIF(GREATEST(?, 0), 0)", d.stgp_debt_median),
        cost_field: "Debt",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("? - NULLIF(GREATEST(?, 0), 0)", d.earnings_1yr, d.stgp_debt_median),
        months: fragment("NULLIF(GREATEST(?, 0), 0)::float * 12 / ?", d.stgp_debt_median, d.earnings_1yr),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        tuition_out: c.tuition_out,
        tuition_in: c.tuition_in,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url,
        has_major_debt: d.stgp_debt_median > 0,
        parent_debt: fragment("NULLIF(GREATEST(?, 0), 0)", d.pp_debt_median),
        net_price: fragment("NULLIF(GREATEST(?, 0), 0)", field(c, ^column)),
        sticker: fragment("NULLIF(GREATEST(?, 0), 0)", c.yearly_cost),
        value_years:
          fragment("NULLIF(GREATEST(?, 0), 0)::float * ? / ?", field(c, ^column), type(^@years_of_study, :integer), d.earnings_1yr)
      }
  end
end
