defmodule Collegevalue.Repo.Migrations.CreateRanks do
  use Ecto.Migration

  def change do
    create table(:ranks) do

      timestamps()
    end

  end
end
