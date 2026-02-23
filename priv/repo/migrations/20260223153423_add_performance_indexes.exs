defmodule Collegevalue.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Indexes for the distance calculation query (with_location)
    create index(:colleges, [:latitude, :longitude])
    create index(:colleges, [:sat_avg])

    # Indexes for discipline joins and filters
    create index(:disciplines, [:name])
    create index(:disciplines, [:credential_level])
    create index(:disciplines, [:college_id, :name, :credential_level])

    # Index for zipcode lookups
    create index(:zips, [:zipcode])
  end
end
