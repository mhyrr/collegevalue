defmodule CollegevalueWeb.FieldView do
  use CollegevalueWeb, :view

  def cash(dollars) do
    Number.Currency.number_to_currency(dollars)
  end

end
