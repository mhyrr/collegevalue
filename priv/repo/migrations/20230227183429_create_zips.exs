defmodule Collegevalue.Repo.Migrations.CreateZips do
  use Ecto.Migration

  def change do
    create table(:zips) do
      add :zipcode, :string
      add :latitude, :float
      add :longitude, :float

      timestamps()
    end
  end
end
