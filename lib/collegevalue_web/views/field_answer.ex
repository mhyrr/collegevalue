defmodule CollegevalueWeb.FieldAnswer do
  @moduledoc """
  The field page's answer to "is a <major> degree worth it?", computed from
  `Collegevalue.FieldNotes.Facts`. Code decides the verdict and picks the
  figures; nothing here is written by a model, so every major with facts gets
  the same answer, whether or not it has field notes.

  The verdict rests on one measure: how many months of first-year pay the
  major's median student debt equals. The common rule of thumb is to borrow
  no more in total than you expect to earn in your first year, 12 months
  here. Federal loan limits keep most majors' debt in a narrow range, so
  nearly every major passes that rule: the typical major takes 8 months and
  only about one in ten takes over 11.5 (2025 Scorecard release). The bands
  sit on that spread, and the verdict also says where the major ranks.
  """

  import CollegevalueWeb.Views.Helpers, only: [cash: 1, months: 1]

  # {upper bound in months, tone, the short answer}. The first band a major's
  # months fall under is its verdict.
  @verdicts [
    {6, :good, "Usually, yes."},
    {9, :good, "Usually, if you borrow the typical amount."},
    {12, :mixed, "Usually, but it pays back slower than most majors."},
    {:infinity, :poor, "Often not, on first-year pay alone."}
  ]
  @rule_months 12
  # A group needs this many programs before the page quotes its figures.
  @min_group 3

  @control_labels [public: "Public", private_nonprofit: "Private nonprofit", for_profit: "For-profit"]
  @band_labels %{
    "under_10_percent" => "Admit under 10%",
    "10_to_25_percent" => "Admit 10–25%",
    "25_to_60_percent" => "Admit 25–60%",
    "over_60_percent" => "Admit over 60%"
  }

  @doc """
  `%{tone, headline, sentences}` for the major, or nil when too few programs
  report both debt and earnings to judge.
  """
  def verdict(%{months_to_repay: %{of_major: m} = spread} = facts) when is_number(m) and m > 0 do
    {_, tone, headline} = Enum.find(@verdicts, fn {max, _, _} -> max == :infinity or m <= max end)

    rule =
      cond do
        m <= @rule_months / 2 -> "well inside the common rule of thumb to borrow no more than a year's pay."
        m <= @rule_months -> "inside the common rule of thumb to borrow no more than a year's pay."
        m <= @rule_months * 1.5 -> "past the common rule of thumb to borrow no more than a year's pay."
        true -> "well past the common rule of thumb to borrow no more than a year's pay."
      end

    spread_sentence =
      cond do
        spread.programs < 4 or not is_number(spread.p25) or not is_number(spread.p75) ->
          nil

        spread.p75 >= spread.p25 * 1.4 ->
          "The college matters: at a quarter of the #{spread.programs} programs that report both, it takes under #{months(spread.p25)}; at another quarter, over #{months(spread.p75)}."

        true ->
          "The college matters less than the major: the middle half of the #{spread.programs} programs that report both take between #{months(spread.p25)} and #{months(spread.p75)}."
      end

    %{
      tone: tone,
      headline: headline,
      sentences: Enum.filter(["Graduates who borrowed owe about #{months(m)} of first-year pay at the median, #{rule}", rank_sentence(facts), spread_sentence], & &1)
    }
  end

  def verdict(_facts), do: nil

  # Rank 1 carries the least debt for the pay.
  defp rank_sentence(%{rank: rank, ranked_of: of}) when is_integer(rank) and of > 1 do
    # Capped at 99, so the first and last majors don't read as 100%.
    slower = min(round((rank - 1) / of * 100), 99)
    faster = min(round((of - rank) / of * 100), 99)

    if slower >= 50,
      do: "That is slower than #{slower}% of majors.",
      else: "That is faster than #{faster}% of majors."
  end

  defp rank_sentence(_facts), do: nil

  @doc "Public, private nonprofit and for-profit programs, each with enough programs to quote."
  def control_rows(%{by_control: by_control} = facts) do
    rows =
      for {key, label} <- @control_labels,
          group = Map.get(by_control, key),
          group && group.programs >= @min_group,
          do: Map.put(group, :label, label)

    online = facts[:online_only]
    rows = if online && online.programs >= @min_group, do: rows ++ [Map.put(online, :label, "Online only")], else: rows

    if length(rows) >= 2, do: rows, else: []
  end

  def control_rows(_facts), do: []

  @doc "A sentence comparing the fastest and slowest school type to repay, or nil."
  def control_sentence(rows) do
    timed = Enum.filter(rows, &(is_number(&1.months_to_repay_median) and &1.label != "Online only"))

    if length(timed) >= 2 do
      fast = Enum.min_by(timed, & &1.months_to_repay_median)
      slow = Enum.max_by(timed, & &1.months_to_repay_median)

      if slow.months_to_repay_median >= fast.months_to_repay_median * 1.25 do
        "#{slow.label} programs take #{months(slow.months_to_repay_median)} of pay to repay at the median, against #{months(fast.months_to_repay_median)} at #{String.downcase(fast.label)} ones."
      else
        "School type barely changes the payback: #{months(fast.months_to_repay_median)} at the fastest type, #{months(slow.months_to_repay_median)} at the slowest."
      end
    end
  end

  @doc "Admission-rate bands with enough programs to quote, most selective first."
  def admission_rows(%{by_admission: bands}) do
    rows = for band <- bands, band.programs >= @min_group, do: Map.put(band, :label, Map.fetch!(@band_labels, band.band))
    if length(rows) >= 2, do: rows, else: []
  end

  def admission_rows(_facts), do: []

  @doc "A sentence on how much more the most selective band pays than the least, or nil."
  def admission_sentence([_, _ | _] = rows) do
    top = List.first(rows)
    open = List.last(rows)

    if is_number(top.earnings_median) and is_number(open.earnings_median) and open.earnings_median > 0 do
      gap = round((top.earnings_median - open.earnings_median) / open.earnings_median * 100)

      cond do
        gap >= 15 -> "Graduates of the most selective colleges earn #{gap}% more in their first year than graduates of the least selective."
        gap <= -5 -> "Graduates of the least selective colleges earn more in their first year than graduates of the most selective."
        true -> "A selective college barely changes first-year pay in this major: the gap between the most and least selective is #{abs(gap)}%."
      end
    end
  end

  def admission_sentence(_rows), do: nil

  @doc "Four years of net price by family income, as `{label, dollars}`, plus the sticker price."
  def cost_rows(%{four_year_cost: cost}) do
    rows =
      [
        {"$0–30k income", cost.income_0_30k},
        {"$48–75k income", cost.income_48_75k},
        {"$110k+ income", cost.income_110k_plus},
        {"Sticker price", cost.sticker}
      ]
      |> Enum.filter(fn {_, v} -> is_number(v) and v > 0 end)

    if length(rows) >= 2, do: rows, else: []
  end

  def cost_rows(_facts), do: []

  @doc "What a $48–75k family still pays after the program's median federal loan, or nil."
  def cost_sentence(%{four_year_cost: %{gap_48_75k: gap, years_of_pay_48_75k: years}}) when is_number(gap) and is_number(years) do
    "At the median program, a family earning $48–75k pays #{cash(gap)} beyond the student's federal loans over four years. The full four-year net price comes to #{years} years of the graduate's first-year pay."
  end

  def cost_sentence(_facts), do: nil

  @doc "The Parent PLUS sentence, when enough programs report parents' loans."
  def parent_sentence(%{parent_plus_over_24_months: %{programs: over, of: of}}) when of >= 10 do
    share = round(over / of * 100)

    if over == 0 do
      "At none of the #{of} programs that report Parent PLUS loans do parents owe more than two years of their graduate's first-year pay."
    else
      "At #{over} of the #{of} programs that report Parent PLUS loans (#{share}%), parents owe more than two years of their graduate's first-year pay. Those loans are the parents' and don't appear in the student's debt."
    end
  end

  def parent_sentence(_facts), do: nil

  @doc """
  Two programs close together with about the same pay and very different
  debt, each with the unitid of its college from `majors` for a link, or nil.
  """
  def pair(%{nearby_pair: %{programs: [a, b], miles: miles}}, majors) do
    ids = Map.new(majors, &{&1.college_name, &1.unit_id})
    [low, high] = Enum.sort_by([a, b], & &1.debt)

    %{
      miles: miles,
      programs: Enum.map([low, high], &Map.put(&1, :unit_id, Map.get(ids, &1.college))),
      times: Float.round(high.debt / low.debt, 1)
    }
  end

  def pair(_facts, _majors), do: nil
end
