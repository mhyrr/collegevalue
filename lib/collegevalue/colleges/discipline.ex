defmodule Collegevalue.Colleges.Discipline do
  use Ecto.Schema
  import Ecto.Changeset

  alias Collegevalue.Colleges.College

  schema "disciplines" do
    field :cipcode, :integer
    field :credential_desc, :string
    field :credential_level, :integer

    field :count, :integer

    field :pp_debt_count, :integer
    field :pp_debt_mean, :integer
    field :pp_debt_median, :integer
    field :pp_debt_payment, :integer

    field :stgp_debt_count, :integer
    field :stgp_debt_mean, :integer
    field :stgp_debt_median, :integer
    field :stgp_debt_payment, :integer

    field :earnings_1yr, :integer
    field :earnings_1yr_count, :integer
    field :earnings_2yr, :integer
    field :earnings_2yr_count, :integer
    field :name, :string
    field :titleiv_count, :integer

    belongs_to :college, College

    timestamps()
  end

  @doc false
  def changeset(discipline, attrs) do
    discipline
    |> cast(attrs, [:cipcode, :name, :credential_level, :credential_desc, :count, :pp_debt_count, :pp_debt_mean, :pp_debt_median, :pp_debt_payment, :stgp_debt_count, :stgp_debt_mean, :stgp_debt_median, :stgp_debt_payment, :titleiv_count, :earnings_1yr_count, :earnings_1yr, :earnings_2yr_count, :earnings_2yr, :college_id])
    |> validate_required([:cipcode, :name, :credential_level, :credential_desc, :count, :pp_debt_count, :pp_debt_mean, :pp_debt_median, :pp_debt_payment, :stgp_debt_count, :stgp_debt_mean, :stgp_debt_median, :stgp_debt_payment, :titleiv_count, :earnings_1yr_count, :earnings_1yr, :earnings_2yr_count, :earnings_2yr])
    |> foreign_key_constraint(:college_id)
  end
end
