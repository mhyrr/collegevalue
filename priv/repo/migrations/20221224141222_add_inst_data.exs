defmodule Collegevalue.Repo.Migrations.AddInstData do
  use Ecto.Migration

  def change do

    alter table("colleges") do

      modify :sat_avg, :integer

      add :ugds, :integer
      add :ugds_men, :float
      add :ugds_women, :float

      add :sat_verbal_25, :integer
      add :sat_verbal_mid, :integer
      add :sat_verbal_75, :integer
      add :sat_math_25, :integer
      add :sat_math_mid, :integer
      add :sat_math_75, :integer
      add :act_comp_25, :integer
      add :act_comp_mid, :integer
      add :act_comp_75, :integer

      add :low_income_debt_median, :integer
      add :medium_income_debt_median, :integer
      add :high_income_debt_median, :integer

      add :fouryear_200_completion, :float
      add :l4y_200_completion, :float

      add :low_family_earnings_median_after6, :integer
      add :medium_family_earnings_median_after6, :integer
      add :high_family_earnings_median_after6, :integer
      add :low_family_earnings_median_after8, :integer
      add :medium_family_earnings_median_after8, :integer
      add :high_family_earnings_median_after8, :integer
      add :low_family_earnings_median_after10, :integer
      add :medium_family_earnings_median_after10, :integer
      add :high_family_earnings_median_after10, :integer

      add :latitude, :float
      add :longitude, :float
      add :distanceonly, :integer
      add :net_tuition_revenue, :integer
      add :institutional_expense_per, :integer
      add :avg_faculty_salary, :integer

    end

  end
end
