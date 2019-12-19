defmodule Collegevalue.Repo.Migrations.CreateFieldsView do
  use Ecto.Migration

  def up do

    execute """
      create view fields as
        select name, count(name), avg(case when debt_mean > 0 then debt_mean end) as debt_avg,
        min(case when debt_mean > 0 then debt_mean end) as debt_min,
        max(case when debt_mean > 0 then debt_mean end) as debt_max,
        avg(case when earnings > 0 then earnings end) as earn_avg,
        min(case when earnings > 0 then earnings end) as earn_min,
        max(case when earnings > 0 then earnings end) as earn_max
          from disciplines where credential_level = 3 group by name;
    """

  end

  def down do
    execute "DROP VIEW fields;"
  end

end
