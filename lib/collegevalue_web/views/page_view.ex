defmodule CollegevalueWeb.PageView do
  use CollegevalueWeb, :view

  import CollegevalueWeb.Views.Helpers, only: [field_page_path: 1, field_short_name: 1, cash: 1]

  @doc "A pay premium as a whole percent: 0.315 is \"32%\"."
  def percent_more(premium), do: "#{round(premium * 100)}%"

  @doc "Names joined for a sentence: \"A, B and C\"."
  def and_join([one]), do: one
  def and_join(names), do: Enum.join(Enum.drop(names, -1), ", ") <> " and " <> List.last(names)
end
