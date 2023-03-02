defmodule Collegevalue.Location.Zipcode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "zips" do
    field :latitude, :float
    field :longitude, :float
    field :zipcode, :string

    timestamps()
  end

  @doc false
  def changeset(zipcode, attrs) do
    zipcode
    |> cast(attrs, [:zipcode, :latitude, :longitude])
    |> validate_required([:zipcode, :latitude, :longitude])
  end
end
