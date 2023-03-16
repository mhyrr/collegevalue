defmodule Collegevalue.Fields.Rank do
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
    field :unit_id, :integer
    field :college_id, :integer
    field :admissions, :float
    field :tuition_out, :integer
    field :tuition_in, :integer
    field :sat_avg, :float
    field :url, :string

    timestamps()
  end

end
