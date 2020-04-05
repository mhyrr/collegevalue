defmodule CollegevalueWeb.Views.Helpers do

  alias Collegevalue.Credential

  @field_rank_views [
    {"Top College/Majors By Debt to Earnings Ratio", "top_debt_to_earnings"},
    {"Bottom College/Majors By Debt to Earnigns Ratio", "bottom_debt_to_earnings"}
  ]


  @college_rank_views [
    {"Top Colleges By Debt to 10 Year Earnings", "top_college_debt_to_earnings"},
    {"Bottom Colleges By Debt to 10 Year Earnings", "bottom_college_debt_to_earnings"},
    {"Top Colleges By Graduated Debt to 10 Year Earnings", "top_college_graddebt_to_earnings"},
    {"Bottom Colleges By Graduated Debt to 10 Year Earnings", "bottom_college_graddebt_to_earnings"},
    {"Top Colleges By Yearly Cost to Earnings", "top_college_yearly_earnings"},
    {"Bottom Colleges By Yearly Cost to Earnings", "bottom_college_yearly_earnings"},
  ]

  def college_rank_views() do
    @college_rank_views
  end

  def field_rank_views() do
    @field_rank_views
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

  def sat(-1.0) do
    "No data"
  end

  def sat(score) do
    score |> round |> Integer.to_string
  end

  def degree("Unknown") do
    ""
  end

  def degree(level) do
    Credential.lookup(level)
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

  def show_credentials() do
    "Bachelor's Only"
  end

  @spec sort_dir(map) :: <<_::24, _::_*8>>
  def sort_dir(order) do
    case order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "asc"
    end
  end

  def chart_data(ranks) do

    chart_data = []

    diffs =
      ranks
      |> Enum.map(fn rank -> [chart_name(rank), rank.diff] end)
      |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Difference", data: diffs}]

    debt = ranks
    |> Enum.map(fn rank -> [chart_name(rank), -rank.cost] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Debt", data: debt}]

    earnings = ranks
    |> Enum.map(fn rank -> [chart_name(rank), rank.payoff] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Earnings", data: earnings}]

    chart_data
  end


  defp chart_name(rank) do
    rank.college_name <> " " <> rank.field_name
  end

  def show_credentials() do
    "Bachelor's Only"
  end

end


