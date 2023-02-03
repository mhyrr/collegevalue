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

  def get_bachelors_earnings(sort \\ "top", limit \\ 100) do

    direction = if sort == "top", do: :desc, else: :asc

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr != -1,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: d.pp_debt_mean,
        cost_field: "Debt Mean",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("d1.earnings_1yr - d1.pp_debt_mean as diff"),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url
      },
      order_by: [{^direction, d.earnings_1yr}],
      limit: ^limit

    # IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, query))

    Repo.all(query)

  end

  def get_bachelors_debt_earnings(sort \\ "top", limit \\ 100) do

    direction = if sort == "top", do: :desc, else: :asc

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr != -1 and d.pp_debt_mean != -1,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: d.pp_debt_mean,
        cost_field: "Debt Mean",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("d1.earnings_1yr - d1.pp_debt_mean as diff"),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url
      },
      order_by: [{^direction, fragment("diff")}],
      limit: ^limit

    # IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, query))

    Repo.all(query)
  end



end
