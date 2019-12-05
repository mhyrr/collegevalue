defmodule Collegevalue.Repo.Migrations.CreateDisciplines do
  use Ecto.Migration

  def change do
    create table(:disciplines) do
      add :cipcode, :integer
      add :name, :string
      add :credential_level, :integer
      add :credential_desc, :string
      add :debt_count, :integer
      add :debt_mean, :integer
      add :debt_median, :integer
      add :debt_payment, :integer
      add :titleiv_count, :integer
      add :earnings_count, :integer
      add :earnings, :integer
      add :college_id, references(:colleges, on_delete: :nothing)

      timestamps()
    end

    create index(:disciplines, [:college_id])
  end
end
