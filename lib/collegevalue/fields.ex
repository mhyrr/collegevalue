defmodule Collegevalue.Fields do
  @moduledoc """
  The Fields context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Fields.{Field, Rank}
  alias Collegevalue.Repo

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

  def get_field!(name), do: Repo.get_by(Field, name: name)

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

  def get_bachelors_earnings(sort \\ "top", limit \\ 100, opts \\ []) do
    direction = if sort == "top", do: :desc, else: :asc
    require_debt = Keyword.get(opts, :require_debt, false)

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr > 0,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: fragment("COALESCE(NULLIF(GREATEST(d1.pp_debt_mean, 0), 0), NULLIF(GREATEST(?, 0), 0))", c.debt_median),
        cost_field: "Debt",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("d1.earnings_1yr - COALESCE(NULLIF(GREATEST(d1.pp_debt_mean, 0), 0), NULLIF(GREATEST(?, 0), 0)) as diff", c.debt_median),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        tuition_out: c.tuition_out,
        tuition_in: c.tuition_in,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url,
        has_major_debt: fragment("d1.pp_debt_mean > 0")
      },
      order_by: [{^direction, d.earnings_1yr}],
      limit: ^limit

    query = if require_debt, do: where(query, [_c, d], d.pp_debt_mean > 0), else: query

    Repo.all(query)
  end

  def get_bachelors_debt_earnings(sort \\ "top", limit \\ 100, opts \\ []) do
    direction = if sort == "top", do: :desc, else: :asc
    require_debt = Keyword.get(opts, :require_debt, false)

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr > 0,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: fragment("COALESCE(NULLIF(GREATEST(d1.pp_debt_mean, 0), 0), NULLIF(GREATEST(?, 0), 0))", c.debt_median),
        cost_field: "Debt",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("d1.earnings_1yr - COALESCE(NULLIF(GREATEST(d1.pp_debt_mean, 0), 0), NULLIF(GREATEST(?, 0), 0)) as diff", c.debt_median),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        tuition_out: c.tuition_out,
        tuition_in: c.tuition_in,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url,
        has_major_debt: fragment("d1.pp_debt_mean > 0")
      },
      limit: ^limit

    query = if sort == "top" do
      order_by(query, fragment("diff DESC NULLS LAST"))
    else
      order_by(query, fragment("diff ASC NULLS LAST"))
    end

    query = if require_debt, do: where(query, [_c, d], d.pp_debt_mean > 0), else: query

    Repo.all(query)
  end



end
