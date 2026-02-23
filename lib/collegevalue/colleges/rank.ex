defmodule Collegevalue.Colleges.Rank do
  use Ecto.Schema

  # Ranks correspond to colleges.

  schema "ranks" do

    field :credential_level, :integer
    field :cost, :integer
    field :cost_field, :string
    field :payoff, :integer
    field :payoff_field, :integer
    field :diff, :integer
    field :name, :string
    field :college_name, :string
    field :college_id, :integer
    field :unit_id, :integer
    field :admissions, :float
    field :sat_avg, :float
    field :url, :string
    field :tuition_out, :integer
    field :tuition_in, :integer
    field :fouryear_100_completion, :float
    field :fouryear_150_completion, :float
    field :fouryear_200_completion, :float

    timestamps()
  end

end
