defmodule Collegevalue.FieldNotes.Facts do
  @moduledoc """
  The figures behind a major's "Is it worth it?" answer, from bachelor's
  programs (credential level 3) only.

  Everything a model later writes about a major rests on these facts, and no
  model output may contain a number that isn't here. `hash/1` names a version
  of the facts, so research and notes made from older facts show as stale.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Repo

  @bachelors 3
  # A major needs this many programs reporting both figures to be ranked.
  @min_ranked 5
  @flag_count 3
  # Programs past 2x or under 0.5x the median, beyond the top and bottom few,
  # that go to research. The rest are only counted, by state, in `outliers`.
  @flag_extra 4

  @doc """
  The facts for the major named `name`, or `nil` when no program reports
  earnings.
  """
  def for_field(name) do
    programs = programs(name)
    with_earnings = Enum.filter(programs, &positive?(&1.earnings))

    if with_earnings == [] do
      nil
    else
      earnings = Enum.map(with_earnings, & &1.earnings)
      debts = programs |> Enum.map(& &1.debt) |> Enum.filter(&positive?/1)
      median = percentile(earnings, 0.5)
      ranking = ranking()

      facts = %{
        name: name,
        programs: length(programs),
        programs_with_earnings: length(with_earnings),
        programs_with_debt: length(debts),
        earnings_median: round_to(median),
        earnings_p25: round_to(percentile(earnings, 0.25)),
        earnings_p75: round_to(percentile(earnings, 0.75)),
        debt_median: if(debts == [], do: nil, else: round_to(percentile(debts, 0.5))),
        all_majors_earnings_median: round_to(ranking.earnings_median),
        ranked_of: length(ranking.ranked),
        flagged: flagged(with_earnings, median),
        outliers: outliers(with_earnings, median)
      }

      facts
      |> Map.merge(rank(name, ranking.ranked))
      |> then(&Map.put(&1, :hash, hash(&1)))
    end
  end

  @doc """
  A short, stable name for a version of the facts: the first 12 hex digits of
  a SHA-256 over every fact except the hash itself.
  """
  def hash(facts), do: facts |> Map.delete(:hash) |> stable_hash()

  @doc """
  A 12-hex-digit SHA-256 of `term` that is the same in every VM. Maps are
  sorted by key text first: since OTP 26 a small map's atom keys serialize in
  atom-creation order, which differs between runs.
  """
  def stable_hash(term) do
    term
    |> canonical()
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)
  end

  defp canonical(%{} = map), do: map |> Enum.map(fn {k, v} -> {to_string(k), canonical(v)} end) |> Enum.sort()
  defp canonical(list) when is_list(list), do: Enum.map(list, &canonical/1)
  defp canonical(other), do: other

  @doc """
  The every-major ranking by median debt over median first-year earnings,
  lowest ratio first. Computed once per boot: the data only changes with a
  Scorecard import. Set `config :collegevalue, cache_field_ranking: false` to
  compute it on every call (the tests do).
  """
  def ranking do
    if Application.get_env(:collegevalue, :cache_field_ranking, true) do
      case :persistent_term.get({__MODULE__, :ranking}, nil) do
        nil -> tap(compute_ranking(), &:persistent_term.put({__MODULE__, :ranking}, &1))
        ranking -> ranking
      end
    else
      compute_ranking()
    end
  end

  defp compute_ranking do
    rows =
      Discipline
      |> where([d], d.credential_level == @bachelors)
      |> group_by([d], d.name)
      |> select([d], %{
        name: d.name,
        earnings: fragment("percentile_cont(0.5) within group (order by ?) filter (where ? > 0)", d.earnings_1yr, d.earnings_1yr),
        debt: fragment("percentile_cont(0.5) within group (order by ?) filter (where ? > 0)", d.pp_debt_median, d.pp_debt_median),
        with_earnings: fragment("count(*) filter (where ? > 0)", d.earnings_1yr),
        with_debt: fragment("count(*) filter (where ? > 0)", d.pp_debt_median)
      })
      |> Repo.all()

    ranked =
      rows
      |> Enum.filter(&(&1.with_earnings >= @min_ranked and &1.with_debt >= @min_ranked))
      |> Enum.map(&{&1.name, &1.debt / &1.earnings})
      |> Enum.sort_by(fn {name, ratio} -> {ratio, name} end)

    major_medians = rows |> Enum.map(& &1.earnings) |> Enum.filter(&is_number/1)

    %{ranked: ranked, earnings_median: percentile(major_medians, 0.5)}
  end

  defp rank(name, ranked) do
    case Enum.find_index(ranked, fn {n, _ratio} -> n == name end) do
      nil -> %{rank: nil, debt_to_earnings: nil}
      index -> %{rank: index + 1, debt_to_earnings: ranked |> Enum.at(index) |> elem(1) |> Float.round(2)}
    end
  end

  defp programs(name) do
    Discipline
    |> join(:inner, [d], c in College, on: c.id == d.college_id)
    # unitid -1 marks a college with no Department of Education ID, mostly
    # outside the U.S.; many share it, so research couldn't tell them apart.
    |> where([d, c], d.name == ^name and d.credential_level == @bachelors and c.unitid > 0)
    |> select([d, c], %{
      unitid: c.unitid,
      college: c.name,
      state: c.state,
      earnings: d.earnings_1yr,
      cohort: d.earnings_1yr_count,
      debt: d.pp_debt_median
    })
    |> Repo.all()
  end

  # The programs a reader would ask about: the highest and lowest earners, and
  # the few farthest from the median. Each carries why it was flagged.
  defp flagged(programs, median) do
    sorted = Enum.sort_by(programs, &{-&1.earnings, &1.unitid})
    ends = MapSet.new(Enum.take(sorted, @flag_count) ++ Enum.take(sorted, -@flag_count), & &1.unitid)

    extra =
      sorted
      |> Enum.filter(&(far?(&1, median) and not MapSet.member?(ends, &1.unitid)))
      |> Enum.sort_by(&{-abs(:math.log(&1.earnings / median)), &1.unitid})
      |> Enum.take(@flag_extra)
      |> MapSet.new(& &1.unitid)

    top = sorted |> Enum.take(@flag_count) |> MapSet.new(& &1.unitid)
    bottom = sorted |> Enum.take(-@flag_count) |> MapSet.new(& &1.unitid)

    sorted
    |> Enum.filter(&(MapSet.member?(ends, &1.unitid) or MapSet.member?(extra, &1.unitid)))
    |> Enum.map(fn p ->
      reasons =
        [
          MapSet.member?(top, p.unitid) && "top_#{@flag_count}",
          MapSet.member?(bottom, p.unitid) && "bottom_#{@flag_count}",
          p.earnings > 2 * median && "above_2x_median",
          p.earnings < 0.5 * median && "below_half_median"
        ]
        |> Enum.filter(& &1)

      p |> Map.put(:reasons, reasons) |> Map.update!(:debt, &if(positive?(&1), do: &1))
    end)
  end

  defp far?(p, median), do: p.earnings > 2 * median or p.earnings < 0.5 * median

  # Every program past 2x or under 0.5x the median, counted, with the states
  # that hold most of them: 30 low-paying nursing programs in Puerto Rico are
  # one finding, not 30.
  defp outliers(programs, median) do
    for {key, test} <- [above_2x_median: &(&1.earnings > 2 * median), below_half_median: &(&1.earnings < 0.5 * median)],
        into: %{} do
      matching = Enum.filter(programs, test)

      states =
        matching
        |> Enum.frequencies_by(& &1.state)
        |> Enum.sort_by(fn {state, n} -> {-n, state} end)
        |> Enum.take(3)
        |> Map.new()

      {key, %{count: length(matching), top_states: states}}
    end
  end

  @doc """
  The `p` percentile of `values`, interpolated the way Postgres's
  `percentile_cont` does it.
  """
  def percentile([], _p), do: nil

  def percentile(values, p) do
    sorted = Enum.sort(values)
    position = p * (length(sorted) - 1)
    lower = floor(position)
    upper = ceil(position)
    low = Enum.at(sorted, lower)
    low + (Enum.at(sorted, upper) - low) * (position - lower)
  end

  defp round_to(nil), do: nil
  defp round_to(value), do: round(value)

  defp positive?(value) when is_number(value), do: value > 0
  defp positive?(_value), do: false
end
