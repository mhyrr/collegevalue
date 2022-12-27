defmodule Collegevalue.Repo.Migrations.CreateColleges do
  use Ecto.Migration

  def change do
    create table(:colleges) do
      add :name, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :opeid, :string
      add :unitid, :integer
      add :control, :string
      add :url, :string
      add :accreditation, :string
      add :admissions_rate, :float
      add :high_degree, :integer
      add :institution_level, :integer
      add :predominant_degree, :integer
      add :inst_degree, :integer
      add :sat_avg, :float
      add :yearly_cost, :integer
      add :tuition_out, :integer
      add :tuition_in, :integer
      add :debt_median, :integer
      add :graduated_debt_median, :integer
      add :withdrawn_debt_median, :integer
      add :netprice_1, :integer
      add :netprice_2, :integer
      add :netprice_3, :integer
      add :netprice_4, :integer
      add :netprice_5, :integer
      add :fouryear_100_completion, :float
      add :fouryear_150_completion, :float
      add :l4y_100_completion, :float
      add :l4y_150_completion, :float
      add :earnings_mean_after10, :integer
      add :earnings_mean_after9, :integer
      add :earnings_mean_after8, :integer
      add :earnings_mean_after7, :integer
      add :earnings_mean_after6, :integer
      add :earnings_median_after10, :integer
      add :earnings_median_after9, :integer
      add :earnings_median_after8, :integer
      add :earnings_median_after7, :integer
      add :earnings_median_after6, :integer


      timestamps()
    end

    create unique_index(:colleges, [:name, :state])
    create unique_index(:colleges, [:unitid])
  end
end
