defmodule CollegevalueWeb.FieldView do
  use CollegevalueWeb, :view

  def cash(dollars) do
    case dollars do
      0 ->
        nil
      _ ->
        Number.Currency.number_to_currency(dollars)
    end
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
