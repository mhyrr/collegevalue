defmodule Collegevalue.Repo.Migrations.FieldsViewStudentLoanDebt do
  use Ecto.Migration

  # A field's debt figures now come from each program's median federal
  # student-loan debt (stgp_debt_median), not its Parent PLUS mean, which
  # describes loans parents took. Missing figures are stored as -1 or -2.

  def up do
    execute "DROP VIEW fields;"

    execute """
      create view fields as
        select name, count(name),
        avg(case when stgp_debt_median > 0 then stgp_debt_median end) as debt_avg,
        min(case when stgp_debt_median > 0 then stgp_debt_median end) as debt_min,
        max(case when stgp_debt_median > 0 then stgp_debt_median end) as debt_max,
        avg(case when earnings_1yr > 0 then earnings_1yr end) as earn_avg,
        min(case when earnings_1yr > 0 then earnings_1yr end) as earn_min,
        max(case when earnings_1yr > 0 then earnings_1yr end) as earn_max
          from disciplines where credential_level = 3 group by name;
    """
  end

  def down do
    execute "DROP VIEW fields;"

    execute """
      create view fields as
        select name, count(name),
        avg(case when pp_debt_mean > 0 then pp_debt_mean end) as debt_avg,
        min(case when pp_debt_mean > 0 then pp_debt_mean end) as debt_min,
        max(case when pp_debt_mean > 0 then pp_debt_mean end) as debt_max,
        avg(case when earnings_1yr > 0 then earnings_1yr end) as earn_avg,
        min(case when earnings_1yr > 0 then earnings_1yr end) as earn_min,
        max(case when earnings_1yr > 0 then earnings_1yr end) as earn_max
          from disciplines where credential_level = 3 group by name;
    """
  end
end
