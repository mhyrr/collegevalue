defmodule CollegevalueWeb.Views.Helpers do

  alias Collegevalue.Credential
  alias Collegevalue.Control
  alias Collegevalue.Colleges.College

  @field_rank_views [
    {"Fastest to Repay the Debt", "fastest_repay"},
    {"Slowest to Repay the Debt", "slowest_repay"},
    {"Best Value for the Cost", "best_value"},
    {"Worst Value for the Cost", "worst_value"},
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
  def no_data?(%Decimal{} = value), do: not Decimal.gt?(value, 0)
  def no_data?(_), do: false

  @doc """
  Months to repay for a program (a `Discipline`): its median student-loan
  debt over one month of its first-year earnings, or nil.
  """
  def program_months(%{stgp_debt_median: debt, earnings_1yr: earnings}),
    do: Collegevalue.Fields.months_to_repay(debt, earnings)

  @doc """
  Years of first-year pay to cover four years of the program's school net
  price for the income bracket (a `Discipline` with its college), or nil.
  """
  def program_value_years(%{college: college, earnings_1yr: earnings}, income),
    do: Collegevalue.Fields.value_years(Collegevalue.Fields.net_price(college, income), earnings)

  @doc """
  Months to repay for display: one decimal under 10 months ("1.5 months"),
  whole months from 10 up ("36 months"), "N/A" with no figure.
  """
  def months(nil), do: "N/A"

  def months(value) when is_number(value) and value > 0 do
    rounded = Float.round(value * 1.0, 1)

    cond do
      rounded >= 10 -> "#{round(value)} months"
      rounded < 0.1 -> "under 0.1 months"
      true -> "#{:erlang.float_to_binary(rounded, decimals: 1)} months"
    end
  end

  def months(_value), do: "N/A"

  defdelegate parent_plus_warning_months, to: Collegevalue.Fields

  @income_bracket_labels %{
    1 => "$0–30,000",
    2 => "$30,000–48,000",
    3 => "$48,000–75,000",
    4 => "$75,000–110,000",
    5 => "$110,000 or more"
  }

  @doc "Family-income brackets for a select: `{label, bracket}`."
  def income_bracket_options do
    for bracket <- Collegevalue.Fields.income_brackets(), do: {@income_bracket_labels[bracket], bracket}
  end

  @doc ~S|The bracket's income range, as in "for families earning $48,000–75,000".|
  def income_bracket_label(bracket), do: @income_bracket_labels[Collegevalue.Fields.income_bracket(bracket)]

  @doc """
  The heading for a /fields/rank view: what the ranking measures.
  """
  def field_rank_heading("slowest_repay"), do: "Slowest to repay: most months of first-year pay to clear the debt"
  def field_rank_heading("best_value"), do: "Best value: fewest years of pay to cover the cost"
  def field_rank_heading("worst_value"), do: "Worst value: most years of pay to cover the cost"
  def field_rank_heading("top_earnings"), do: "Highest first-year pay"
  def field_rank_heading("bottom_earnings"), do: "Lowest first-year pay"
  def field_rank_heading(_ranking), do: "Fastest to repay: fewest months of first-year pay to clear the debt"

  @doc "Whether a /fields/rank view needs the note about majors that lead to graduate school."
  def grad_school_note?(ranking), do: ranking in ["slowest_repay", "worst_value"]

  @doc """
  Years of pay for display, one decimal ("1.8 years"); "N/A" with no figure.
  """
  def years(value) when is_number(value) and value > 0 do
    rounded = Float.round(value * 1.0, 1)

    cond do
      rounded < 0.1 -> "under 0.1 years"
      rounded == 1.0 -> "1.0 year"
      true -> "#{:erlang.float_to_binary(rounded, decimals: 1)} years"
    end
  end

  def years(_value), do: "N/A"

  @doc ~S|The gap after federal loans for display: "$93k beyond federal loans".|
  def gap_text(0), do: "$0 beyond federal loans"
  def gap_text(gap) when is_number(gap) and gap > 0, do: "#{cash_compact(gap)} beyond federal loans"
  def gap_text(_gap), do: nil

  @doc """
  The Parent PLUS warning for a program, as a sentence, or nil when its
  Parent PLUS median is within `Fields.parent_plus_warning_months/0` of
  first-year pay (or isn't reported).
  """
  def parent_plus_note(parent_debt, earnings_1yr) do
    case Collegevalue.Fields.parent_plus_warning(parent_debt, earnings_1yr) do
      nil -> nil
      months -> "Parents who borrowed owed a median of #{cash(parent_debt)} (#{round(months)} months of pay)."
    end
  end

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
      |> Enum.map(fn major -> [major.name, (if no_data?(major.earnings) || no_data?(major.debt_median), do: 0, else: major.earnings - major.debt_median)] end)
      |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Difference", data: diffs}]

    debt = majors
    |> Enum.map(fn major -> [major.name, (if no_data?(major.debt_median), do: 0, else: -major.debt_median)] end)
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

    debt = ranks
    |> Enum.map(fn rank -> [chart_name(rank), -(rank.cost || 0)] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Debt", data: debt}]

    earnings = ranks
    |> Enum.map(fn rank -> [chart_name(rank), rank.payoff || 0] end)
    |> Enum.reverse
    chart_data = chart_data ++ [ %{name: "Earnings", data: earnings}]

    chart_data
  end


  defp chart_name(rank) do
    rank.college_name <> " " <> rank.field_name
  end

  @doc """
  "City, ST" for a US college with a listed city, else nil.
  """
  def place(%College{city: city, state: state})
      when is_binary(city) and city not in ["", "city", "unknown city"] and is_binary(state) do
    if state =~ ~r/^[A-Z]{2}$/, do: "#{city}, #{state}"
  end

  def place(_college), do: nil

  @doc """
  The page title for a college: its name, and its place when known, so
  colleges that share a name get titles of their own.
  """
  def college_title(%College{name: name} = college) do
    case place(college) do
      nil -> name
      place -> "#{name} (#{place})"
    end
  end

  @doc """
  The field page's title, phrased as the question people search for, with
  the field's short name: nobody searches "Psychology, General".
  """
  def field_title(%{name: name}),
    do: "Is #{field_short_name(name)} Worth It? Debt vs. Earnings by College"

  def field_short_name(name), do: Collegevalue.Fields.short_name(name)

  @doc """
  The path of a field's page, by its slug: `/fields/psychology`. Every link
  to a field page goes through here, so none points at an old name URL.
  """
  def field_page_path(name, params \\ %{}) do
    CollegevalueWeb.Router.Helpers.live_path(
      CollegevalueWeb.Endpoint,
      CollegevalueWeb.FieldsLive.Show,
      Collegevalue.Fields.slug(name),
      params
    )
  end

  @doc """
  The question a field page answers: "Is a Psychology degree worth it?"
  """
  def field_question(name) do
    short = field_short_name(name)
    article = if short =~ ~r/^[AEIOU]/i, do: "an", else: "a"
    "Is #{article} #{short} degree worth it?"
  end

  @doc """
  The answer to `field_question/1`, as sentences built from
  `Collegevalue.FieldNotes.Facts`. Every figure comes from the facts; there is
  no verdict, because one year of earnings can't carry one.
  """
  def field_answer(nil), do: []

  def field_answer(facts) do
    [
      "Across #{facts.programs_with_earnings} bachelor's #{if facts.programs_with_earnings == 1, do: "program", else: "programs"} that report earnings, " <>
        "the median pays its graduates #{cash(facts.earnings_median)} a year after graduation" <>
        if(facts.programs_with_earnings >= 4,
          do: ", and the middle half pay between #{cash(facts.earnings_p25)} and #{cash(facts.earnings_p75)}.",
          else: "."
        ),
      "The median for all majors is #{cash(facts.all_majors_earnings_median)}.",
      facts.debt_median &&
        "At the median program, graduates who borrowed owe #{cash(facts.debt_median)}.",
      facts.rank &&
        "Debt is #{facts.debt_to_earnings}x first-year earnings, which ranks #{ordinal(facts.rank)} of #{facts.ranked_of} majors, where 1st carries the least debt for the pay."
    ]
    |> Enum.filter(&is_binary/1)
  end

  def ordinal(n) when rem(n, 100) in 11..13, do: "#{n}th"
  def ordinal(n) when rem(n, 10) == 1, do: "#{n}st"
  def ordinal(n) when rem(n, 10) == 2, do: "#{n}nd"
  def ordinal(n) when rem(n, 10) == 3, do: "#{n}rd"
  def ordinal(n), do: "#{n}th"

  @doc """
  A paragraph on the college built from the figures it reports. Empty when it
  reports none of them.
  """
  def college_summary(%College{} = college) do
    control = if is_binary(college.control), do: control(college.control), else: ""

    [
      is_binary(college.control) && college.control =~ ~r/^[123]$/ && place(college) &&
        "#{college.name} is a #{String.downcase(control)} college in #{place(college)}.",
      !no_data?(college.yearly_cost) &&
        "A year there costs #{cash(college.yearly_cost)} on average, tuition, fees, books and living costs together.",
      !no_data?(college.debt_median) &&
        "Students who borrow leave with a median federal debt of #{cash(college.debt_median)}.",
      !no_data?(college.earnings_median_after10) &&
        "Ten years after they start, its students earn a median of #{cash(college.earnings_median_after10)} a year.",
      !no_data?(college.fouryear_150_completion) &&
        "#{percent(college.fouryear_150_completion)} of full-time, first-time students finish within six years."
    ]
    |> Enum.filter(&is_binary/1)
    |> summary_text(1)
  end

  @doc """
  A paragraph on the field built from its debt and earnings across colleges.
  Empty when no college reports either.
  """
  def field_summary(%Collegevalue.Fields.Field{} = field) do
    [
      "#{field.count} #{if field.count == 1, do: "college offers", else: "colleges offer"} #{field.name} in the College Scorecard data.",
      !no_data?(field.debt_avg) &&
        "At the average program, graduates who borrowed owe a median of #{cash(field.debt_avg)} in federal student loans" <>
          range(field.debt_min, field.debt_max, "program") <> ".",
      !no_data?(field.earn_avg) &&
        "One year after graduating they earn #{cash(field.earn_avg)} on average" <>
          range(field.earn_min, field.earn_max, "program") <> "."
    ]
    |> Enum.filter(&is_binary/1)
    |> summary_text(1)
  end

  # The first `lead` sentences only set the scene; without a figure after them
  # there is no summary.
  defp summary_text(sentences, lead) when length(sentences) > lead, do: Enum.join(sentences, " ")
  defp summary_text(_sentences, _lead), do: ""

  defp range(min, max, unit) do
    if no_data?(min) or no_data?(max) or min == max do
      ""
    else
      ", from #{cash(min)} at the lowest #{unit} to #{cash(max)} at the highest"
    end
  end


end
