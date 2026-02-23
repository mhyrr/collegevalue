defmodule CollegevalueWeb.Views.Helpers do

  alias Collegevalue.Credential
  alias Collegevalue.Control
  alias Collegevalue.Colleges.College

  @field_rank_views [
    {"Top College/Majors By Debt to Earnings Ratio", "top_debt_to_earnings"},
    {"Bottom College/Majors By Debt to Earnigns Ratio", "bottom_debt_to_earnings"},
    {"Top College/Majors by Earnings Only", "top_earnings"},
    {"Bottom College/Majors by Earnings Only", "bottom_earnings"}
  ]


  @college_rank_views [
    {"Top Colleges By Yearly Cost to Earnings", "top_college_yearly_earnings"},
    {"Bottom Colleges By Yearly Cost to Earnings", "bottom_college_yearly_earnings"},

    {"Top Colleges By Graduated Debt to 10 Year Earnings", "top_college_graddebt_to_earnings"},
    {"Bottom Colleges By Graduated Debt to 10 Year Earnings", "bottom_college_graddebt_to_earnings"},
    {"Top Colleges By Debt to 10 Year Earnings", "top_college_debt_to_earnings"},
    {"Bottom Colleges By Debt to 10 Year Earnings", "bottom_college_debt_to_earnings"},
  ]

  def college_rank_views() do
    @college_rank_views
  end

  def field_rank_views() do
    @field_rank_views
  end

  def address(%College{city: city, state: state, zip: zip}) when city == "city" or state == "state" or zip == "zip" do
    "Not Listed"
  end

  def address(college) do
    college.city <> ", " <> college.state <> " " <> college.zip
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

  def sat(nil) do
    "No data"
  end

  def sat(-1) do
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

  def control(control) do
    case Integer.parse(control) do
      {c, _} ->
        Control.lookup(c)
      _ ->
        control
    end
  end

  def accreditation(acc) do
    case acc do

      "NULL" ->
        "None Listed"
      "EXEMPT" ->
        "Exempt"
      "unknown acc" ->
        "Unknown"
      _ ->
        acc
    end
  end

  def no_data?(nil), do: true
  def no_data?(0), do: true
  def no_data?(-1), do: true
  def no_data?(-2), do: true
  def no_data?(-1.0), do: true
  def no_data?("No data"), do: true
  def no_data?(_), do: false

  def cash(val) when is_nil(val), do: "No data"

  def cash(dollars) do
    if no_data?(dollars) do
      "No data"
    else
      Number.Currency.number_to_currency(dollars, precision: 0)
    end
  end

  def cash_compact(val) when is_nil(val), do: "N/A"

  def cash_compact(dollars) do
    if no_data?(dollars) do
      "N/A"
    else
      cond do
        dollars >= 1_000_000 ->
          "$#{Float.round(dollars / 1_000_000, 1)}M"
        dollars >= 1000 ->
          "$#{round(dollars / 1000)}k"
        dollars <= -1_000_000 ->
          "-$#{Float.round(abs(dollars) / 1_000_000, 1)}M"
        dollars <= -1000 ->
          "-$#{round(abs(dollars) / 1000)}k"
        true ->
          "$#{dollars}"
      end
    end
  end

  @header_map %{
    "debt_median" => "Median Debt",
    "graduated_debt_median" => "Grad Debt",
    "yearly_cost" => "Annual Cost",
    "earnings_median_after10" => "10-Year Earnings",
    "earnings_median_after9" => "9-Year Earnings",
    "earnings_median_after8" => "8-Year Earnings",
    "earnings_median_after7" => "7-Year Earnings",
    "earnings_median_after6" => "6-Year Earnings",
    "earnings_mean_after10" => "10-Year Earnings (Mean)",
    "admissions_rate" => "Admit Rate",
    "sat_avg" => "Avg SAT",
    "tuition_in" => "In-State Tuition",
    "tuition_out" => "Out-of-State Tuition",
    "Debt Mean" => "Debt Mean",
    "Field Earnings" => "1-Year Earnings"
  }

  def humanize_header(field_name) do
    Map.get(@header_map, field_name, field_name |> String.replace("_", " ") |> String.capitalize())
  end

  def defaults(geo) do

    case geo do
      "city" ->
        "Unlisted"
      "state" ->
        "Unlisted"
      "unknown city" ->
        "Unlisted"
      "unknown state" ->
        "Unlisted"
      "zip" ->
        nil
      "acc" ->
        "None"
      -1.0 ->
        "No data"
      -1 ->
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

  def shorten(field) do
    if String.length(field) > 36 do
      String.slice(field, 0..35) <> "..."
    else
      field
    end
  end

  def income_cost_chart_data(net_price_bands) do
    net_price_bands
    |> Enum.map(fn {label, value} -> [label, value] end)
  end

  def income_earnings_chart_data(earnings_series) do
    earnings_series
    |> Enum.map(fn {name, data} ->
      %{name: name, data: Enum.map(data, fn {label, val} -> [label, if(is_nil(val) or val <= 0, do: 0, else: val)] end)}
    end)
  end

  def college_chart_data(majors) do

    majors = majors
      |> Enum.filter(fn major -> major.credential_level == 3 end)
      |> Enum.sort(&(&1.earnings >= &2.earnings) )
    chart_data = []

    diffs =
      majors
      |> Enum.map(fn major -> [major.name, (if (major.earnings == -1 || major.debt_mean == -1), do: 0, else: major.earnings - major.debt_mean)] end)
      |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Difference", data: diffs}]

    debt = majors
    |> Enum.map(fn major -> [major.name, -major.debt_mean] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Debt", data: debt}]

    earnings = majors
    |> Enum.map(fn major -> [major.name, major.earnings] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Earnings", data: earnings}]



    chart_data

  end

  def field_chart_data(ranks) do

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


end
