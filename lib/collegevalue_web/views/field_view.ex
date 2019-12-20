defmodule CollegevalueWeb.FieldView do
  use CollegevalueWeb, :view

  def cash(dollars) do
    Number.Currency.number_to_currency(dollars)
  end

  def sort_dir(params) do

    case Map.get(params, "sort_dir") do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "asc"
    end

  end

end
