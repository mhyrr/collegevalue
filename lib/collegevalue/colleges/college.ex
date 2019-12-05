defmodule Collegevalue.Colleges.College do
  use Ecto.Schema
  import Ecto.Changeset

  schema "colleges" do
    field :accreditation, :string
    field :city, :string
    field :control, :string
    field :name, :string
    field :opeid, :integer
    field :state, :string
    field :unitid, :integer
    field :url, :string
    field :zip, :string

    timestamps()
  end

  @doc false
  def changeset(college, attrs) do
    college
    |> cast(attrs, [:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation])
    |> validate_required([:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation])
    |> unique_constraint(:name)
    |> unique_constraint(:opeid)
    |> unique_constraint(:unitid)
  end
end
