defmodule Collegevalue.Colleges.College do
  use Ecto.Schema
  import Ecto.Changeset

  alias Collegevalue.Colleges.Discipline

  schema "colleges" do
    field :accreditation, :string
    field :city, :string
    field :control, :string
    field :name, :string
    field :opeid, :string
    field :state, :string
    field :unitid, :integer
    field :url, :string
    field :zip, :string
    field :admissions_rate, :float
    field :high_degree, :integer
    field :institution_level, :integer
    field :predominant_degree, :integer
    field :inst_degree, :integer
    field :ugds, :integer
    field :ugds_men, :float
    field :ugds_women, :float

    field :sat_avg, :integer
    field :sat_verbal_25, :integer
    field :sat_verbal_mid, :integer
    field :sat_verbal_75, :integer
    field :sat_math_25, :integer
    field :sat_math_mid, :integer
    field :sat_math_75, :integer
    field :act_comp_25, :integer
    field :act_comp_mid, :integer
    field :act_comp_75, :integer

    field :yearly_cost, :integer
    field :tuition_out, :integer
    field :tuition_in, :integer
    field :debt_median, :integer
    field :graduated_debt_median, :integer
    field :withdrawn_debt_median, :integer
    field :low_income_debt_median, :integer
    field :medium_income_debt_median, :integer
    field :high_income_debt_median, :integer

    field :netprice_1, :integer
    field :netprice_2, :integer
    field :netprice_3, :integer
    field :netprice_4, :integer
    field :netprice_5, :integer
    field :fouryear_100_completion, :float
    field :fouryear_150_completion, :float
    field :fouryear_200_completion, :float
    field :l4y_100_completion, :float
    field :l4y_150_completion, :float
    field :l4y_200_completion, :float
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

    field :low_family_earnings_median_after6, :integer
    field :medium_family_earnings_median_after6, :integer
    field :high_family_earnings_median_after6, :integer
    field :low_family_earnings_median_after8, :integer
    field :medium_family_earnings_median_after8, :integer
    field :high_family_earnings_median_after8, :integer
    field :low_family_earnings_median_after10, :integer
    field :medium_family_earnings_median_after10, :integer
    field :high_family_earnings_median_after10, :integer

    field :latitude, :float
    field :longitude, :float
    field :distanceonly, :integer
    field :net_tuition_revenue, :integer
    field :institutional_expense_per, :integer
    field :avg_faculty_salary, :integer

    has_many(:disciplines, Discipline)

    timestamps()
  end

  @doc false
  def changeset(college, attrs) do
    college
    |> cast(attrs, [:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation, :admissions_rate, :high_degree, :institution_level,
        :predominant_degree, :inst_degree, :ugds, :ugds_men, :ugds_women, :sat_avg, :sat_verbal_25, :sat_verbal_mid, :sat_verbal_75,
        :sat_math_25, :sat_math_mid, :sat_math_75, :act_comp_25, :act_comp_mid, :act_comp_75,
        :low_income_debt_median, :medium_income_debt_median,  :high_income_debt_median,
        :yearly_cost, :tuition_out, :tuition_in, :debt_median, :graduated_debt_median, :withdrawn_debt_median, :netprice_1, :netprice_2, :netprice_3,
        :netprice_4, :netprice_5, :fouryear_100_completion, :fouryear_150_completion, :fouryear_200_completion, :l4y_100_completion, :l4y_150_completion,
        :l4y_200_completion, :earnings_mean_after10, :earnings_mean_after9, :earnings_mean_after8,
        :earnings_mean_after7, :earnings_mean_after6, :earnings_median_after10, :earnings_median_after9, :earnings_median_after8, :earnings_median_after7,
        :earnings_median_after6, :low_family_earnings_median_after6, :medium_family_earnings_median_after6,:high_family_earnings_median_after6,
        :low_family_earnings_median_after8, :medium_family_earnings_median_after8,:high_family_earnings_median_after8,
        :low_family_earnings_median_after10, :medium_family_earnings_median_after10,:high_family_earnings_median_after10,
        :latitude, :longitude, :distanceonly, :net_tuition_revenue, :institutional_expense_per, :avg_faculty_salary
        ])
    |> validate_required([:name, :city, :state, :zip, :opeid, :unitid, :control, :url, :accreditation])
    |> unique_constraint([:name, :state])
    |> unique_constraint(:unitid)
  end
end
