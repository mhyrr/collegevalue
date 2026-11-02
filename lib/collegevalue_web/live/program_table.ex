defmodule CollegevalueWeb.ProgramTable do
  @moduledoc """
  Sorting and filtering for the program tables on the field and college pages.

  Scorecard marks a missing number -1 and a privacy-suppressed one -2, so any
  amount that isn't positive sorts after the real numbers in either direction.
  A program with no debt or earnings at all is counted instead of listed.
  """

  @sorts %{
    "credential_level" => :credential_level,
    "debt_mean" => :debt_mean,
    "debt_median" => :debt_median,
    "earnings" => :earnings
  }
  @amounts [:debt_mean, :debt_median, :earnings]

  def sorts, do: ["name" | Map.keys(@sorts)]

  @doc """
  Sorts by a column, highest first for "desc". `name_key` is the field the
  name column shows: the college on a field page, the major on a college page.
  """
  def sort(majors, sort_by, order, name_key) do
    key = if sort_by == "name", do: name_key, else: Map.fetch!(@sorts, sort_by)
    sorted = Enum.sort_by(majors, &(Map.get(&1, key) || -3))
    sorted = if order == "desc", do: Enum.reverse(sorted), else: sorted

    if key in @amounts do
      {data, no_data} = Enum.split_with(sorted, &data?(Map.get(&1, key)))
      data ++ no_data
    else
      sorted
    end
  end

  @doc "The order a column starts in when it is first picked."
  def first_order(sort_by) when sort_by in ["name", "credential_level"], do: "asc"
  def first_order(_sort_by), do: "desc"

  @doc """
  The rows to list, the programs left out for having no data, and how many
  programs with data each credential setting would list.
  """
  def rows(majors, show_all) do
    shown? = &(show_all or &1.credential_level == 3)
    {with_data, empty} = Enum.split_with(majors, fn major -> Enum.any?(@amounts, &data?(Map.get(major, &1))) end)

    %{
      rows: Enum.filter(with_data, shown?),
      no_data_count: Enum.count(empty, shown?),
      bachelors_count: Enum.count(with_data, &(&1.credential_level == 3)),
      all_count: length(with_data)
    }
  end

  defp data?(value), do: is_integer(value) and value > 0
end
