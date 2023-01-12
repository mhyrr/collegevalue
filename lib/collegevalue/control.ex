defmodule Collegevalue.Control do

  @controls %{
    1 => :"Public",
    2 => :"Private Non-Profit",
    3 => :"Private For-Profit"
  }

  def lookup(int), do: do_lookup(int)

  for {int, term} <- @controls do
    defp do_lookup(unquote(int)), do: Atom.to_string(unquote(term))
  end

end
