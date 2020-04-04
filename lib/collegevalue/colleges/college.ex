defmodule Collegevalue.Colleges.College do
  use Ecto.Schema
  import Ecto.Changeset

  alias Collegevalue.Colleges.Discipline

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
    field :admissions_rate, :float
    field :high_degree, :integer
    field :institution_level, :integer
    field :predominant_degree, :integer
    field :inst_degree, :integer
    field :sat_avg, :float
    field :yearly_cost, :integer
    field :tuition_out, :integer
    field :tuition_in, :integer
    field :debt_median, :integer
    field :graduated_debt_median, :integer
    field :withdrawn_debt_median, :integer
    field :netprice_1, :integer
    field :netprice_2, :integer
    field :netprice_3, :integer
    field :netprice_4, :integer
    field :netprice_5, :integer
    field :fouryear_100_completion, :float
    field :fouryear_150_completion, :float
    field :l4y_100_completion, :float
    field :l4y_150_completion, :float
    field :earnings_mean_after10, :integer
    field :earnings_mean_after9, :integer
    field :earnings_mean_after8, :integer
    field :earnings_mean_after7, :integer
    field :earnings_mean_after6, :integer
    field :earnings_median_after10, :integer
    field :earnings_median_after9, :integer
    field :earnings_median_after8, :integer
    field :earnings_median_after7, :integer
    field :earnings_median_after6, :integer

    has_many(:disciplines, Discipline)

    timestamps()
  end

  @doc false
  def changeset(college, attrs) do
    college
    |> cast(attrs, [:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation, :admissions_rate, :high_degree, :institution_level,
        :predominant_degree, :inst_level, :sat_avg, :yearly_cost,
        :tuition_out, :tuition_in, :debt_median, :graduated_debt_median, :withdrawn_debt_median, :netprice_1, :netprice_2, :netprice_3,
        :netprice_4, :netprice_5, :fouryear_100_completion, :fouryear_150_completion, :l4y_100_completion, :l4y_150_completion,
        :earnings_mean_after10, :earnings_mean_after9, :earnings_mean_after8,
        :earnings_mean_after7, :earnings_mean_after6, :earnings_median_after10, :earnings_median_after9, :earnings_median_after8, :earnings_median_after7,
        :earnings_median_after6])
    |> validate_required([:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation])
    |> unique_constraint(:name)
    |> unique_constraint(:unitid)
  end
end
