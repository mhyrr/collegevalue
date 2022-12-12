defmodule Collegevalue.Repo.Migrations.AddFieldsData do
  use Ecto.Migration

  def change do

    rename table("disciplines"), :earnings, to: :earnings_1yr
    rename table("disciplines"), :earnings_count, to: :earnings_1yr_count

    rename table("disciplines"), :debt_mean, to: :pp_debt_mean
    rename table("disciplines"), :debt_median, to: :pp_debt_median
    rename table("disciplines"), :debt_count, to: :pp_debt_count
    rename table("disciplines"), :debt_payment, to: :pp_debt_payment


    alter table("disciplines") do
      add :count, :integer
      add :earnings_2yr, :integer
      add :earnings_2yr_count, :integer
      add :stgp_debt_mean, :integer
      add :stgp_debt_median, :integer
      add :stgp_debt_count, :integer
      add :stgp_debt_payment, :integer
    end


  end
end
