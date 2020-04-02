defmodule CollegevalueWeb.FieldView do
  use CollegevalueWeb, :view

  alias Collegevalue.Credential

  def show_credentials() do
    "Bachelor's Only"
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

  def degree(level) do
    Credential.lookup(level)
  end

  @spec sort_dir(map) :: <<_::24, _::_*8>>
  def sort_dir(order) do
    IO.inspect(order)
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
