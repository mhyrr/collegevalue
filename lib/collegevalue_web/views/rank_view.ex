defmodule CollegevalueWeb.RankView do
  use CollegevalueWeb, :view

  alias Collegevalue.Credential

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


end
