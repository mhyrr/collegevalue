defmodule Collegevalue.Rankings do
  @moduledoc """
  The Rankings context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Repo
  alias Collegevalue.Colleges.{College, Discipline}

  alias Collegevalue.Rankings.Rank

  def get_top_bachelors_debt_earnings(limit \\ 100) do

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
        url: c.url
      },
      order_by: fragment("diff desc"),
      limit: ^limit


    Repo.all(query)

  end






end
