defmodule CollegevalueWeb.DisciplineView do
  use CollegevalueWeb, :view

  alias Collegevalue.Credential

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

  def degree(level) do
    Credential.lookup(level)
  end

end
