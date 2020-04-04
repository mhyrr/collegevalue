defmodule Collegevalue.Rankings do
  @moduledoc """
  The Rankings context.
  """

  import Ecto.Query, warn: false
  import Atom
  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}

  alias Collegevalue.Rankings.Rank

  def get_bachelors_debt_earnings(sort \\ "top", limit \\ 100) do

    direction = if sort == "top", do: :desc, else: :asc

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings != -1 and d.debt_mean != -1,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: d.debt_mean,
        cost_field: "Debt Mean",
        payoff: d.earnings,
        payoff_field: "Field Earnings",
        diff: fragment("d1.earnings - d1.debt_mean as diff"),
        college_name: c.name,
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


  def get_colleges_by_costs(cost_field \\ :debt_median, payoff_field \\ :earnings_median_after10, sort \\ :top, limit \\ 100) do

    direction = if sort == :top, do: :desc, else: :asc

    base = from c in College,
      select: %Rank{
        field_name: "None",
        credential_level: "Unknown",
        cost: field(c, ^cost_field),
        cost_field: ^Atom.to_string(cost_field),
        payoff: field(c, ^payoff_field),
        payoff_field: ^Atom.to_string(payoff_field),
        diff: fragment("? - ? as diff", field(c, ^payoff_field), field(c, ^cost_field)),
        college_name: c.name,
        college_id: c.id,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url
      },
      order_by: [{^direction, fragment("diff")}],
      limit: ^limit

    query =
      base
      |> filter_results(cost_field)
      |> filter_results(payoff_field)

    IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, query))

    Repo.all(query)
  end

  defp filter_results(query, key) do

    from(q in query, where: field(q, ^key) != -1 and field(q, ^key) != -2 and not field(q, ^key) |> is_nil)

  end

end
