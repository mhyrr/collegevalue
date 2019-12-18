defmodule Collegevalue.Credential do

  @credential_by_level %{
    1 => :"Undergraduate Certificate",
    2 => :"Associate's Degree",
    3 => :"Bachelor's Degree",
    4 => :"Post-Baccalaureate Certificate",
    5 => :"Master's Degree",
    6 => :"Doctoral Degree",
    7 => :"First Professional Degree",
    8 => :"Graduate/Professional Certificate"
  }

  def lookup(int), do: do_lookup(int)

  for {int, term} <- @credential_by_level do
    defp do_lookup(unquote(int)), do: Atom.to_string(unquote(term))
  end

end


