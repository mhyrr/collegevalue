defmodule CollegevalueWeb.CollegeView do
  use CollegevalueWeb, :view

  alias Collegevalue.Credential

  @rank_views [
    {"Top Colleges By Debt to 10 Year Earnings", "top_college_debt_to_earnings"},
    {"Bottom Colleges By Debt to 10 Year Earnings", "bottom_college_debt_to_earnings"},
    {"Top Colleges By Graduated Debt to 10 Year Earnings", "top_college_graddebt_to_earnings"},
    {"Bottom Colleges By Graduated Debt to 10 Year Earnings", "bottom_college_graddebt_to_earnings"},
    {"Top Colleges By Yearly Cost to Earnings", "top_college_yearly_earnings"},
    {"Bottom Colleges By Yearly Cost to Earnings", "bottom_college_yearly_earnings"},
  ]

  def rank_views() do
    @rank_views
  end

  def cash(nil) do
    "No data"
  end

  def cash(dollars) do
    case dollars do
      0 ->
        nil
      -1 ->
        nil
      _ ->
        Number.Currency.number_to_currency(dollars)
    end
  end

  @spec percent(nil | float) :: <<_::8, _::_*8>>
  def percent(nil) do
    "No data"
  end

  def percent(-1.0) do
    "No data"
  end

  def percent(adm) do
    adm * 100
    |> Float.round(2)
    |> Float.to_string
    |> Kernel.<>("%")
  end

  def degree("Unknown") do
    ""
  end

  @spec degree(1 | 2 | 3 | 4 | 5 | 6 | 7 | 8) :: any
  def degree(level) do
    Credential.lookup(level)
  end



  def defaults(geo) do

    case geo do
      "city" ->
        nil
      "state" ->
        nil
      "zip" ->
        nil
      "acc" ->
        "None"
      -1.0 ->
        "No data"
      _ ->
        geo
    end

  end

end
