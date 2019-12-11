defmodule Collegevalue.Colleges.Discipline do
  use Ecto.Schema
  import Ecto.Changeset

  alias Collegevalue.Colleges.College

  schema "disciplines" do
    field :cipcode, :integer
    field :credential_desc, :string
    field :credential_level, :integer
    field :debt_count, :integer
    field :debt_mean, :integer
    field :debt_median, :integer
    field :debt_payment, :integer
    field :earnings, :integer
    field :earnings_count, :integer
    field :name, :string
    field :titleiv_count, :integer

    belongs_to :college, College

    timestamps()
  end

  @doc false
  def changeset(discipline, attrs) do
    discipline
    |> cast(attrs, [:cipcode, :name, :credential_level, :credential_desc, :debt_count, :debt_mean, :debt_median, :debt_payment, :titleiv_count, :earnings_count, :earnings, :college_id])
    |> validate_required([:cipcode, :name, :credential_level, :credential_desc, :debt_count, :debt_mean, :debt_median, :debt_payment, :titleiv_count, :earnings_count, :earnings])
    |> foreign_key_constraint(:college_id)
  end
end
