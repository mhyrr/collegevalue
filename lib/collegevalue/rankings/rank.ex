defmodule Collegevalue.Rankings.Rank do
  use Ecto.Schema

  schema "ranks" do

    field :field_name, :string
    field :credential_level, :integer
    field :cost, :integer
    field :cost_field, :string
    field :payoff, :integer
    field :payoff_field, :integer
    field :diff, :integer
    field :name, :string
    field :college_name, :string
    field :college_id, :integer
    field :url, :string

    timestamps()
  end

end
