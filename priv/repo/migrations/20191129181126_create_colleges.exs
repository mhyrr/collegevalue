defmodule Collegevalue.Repo.Migrations.CreateColleges do
  use Ecto.Migration

  def change do
    create table(:colleges) do
      add :name, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :opeid, :integer
      add :unitid, :integer
      add :control, :string
      add :url, :string
      add :accreditation, :string

      timestamps()
    end

    create unique_index(:colleges, [:name])
    create unique_index(:colleges, [:opeid])
    create unique_index(:colleges, [:unitid])
  end
end
