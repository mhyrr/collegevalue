defmodule Collegevalue.Rankings.Rank do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ranks" do

    timestamps()
  end

  @doc false
  def changeset(rank, attrs) do
    rank
    |> cast(attrs, [])
    |> validate_required([])
  end
end
