defmodule CollegevalueWeb.FieldView do
  use CollegevalueWeb, :view

  alias Collegevalue.Credential


  @rank_views [
    {"Top College/Majors By Debt to Earnings Ratio", "top_debt_to_earnings"},
    {"Bottom College/Majors By Debt to Earnigns Ratio", "bottom_debt_to_earnings"}
  ]

  def rank_views() do
    @rank_views
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

end
