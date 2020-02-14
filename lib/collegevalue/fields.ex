defmodule Collegevalue.Fields do
  @moduledoc """
  The Fields context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Fields.Field
  alias Collegevalue.Repo

  def list_fields do

    Repo.all(Field)

    # This needs to be another schema/view

    # Dump this into an ets table later
    # Another select d.debt_mean, d.earnings, c.name, d.credential_level  from disciplines d, colleges c where d.college_id = c.id and d.name = 'Business/Commerce, General.' order by earnings DESC;

  end

  def list_fields(col, order) when is_binary(col) and is_binary(order) do

    sort = String.to_atom(col)
    sort_order = String.to_existing_atom(order)

    Field
    |> order_by({^sort_order, ^sort} )
    |> Repo.all()

  end

  def get_field!(name), do: Repo.get_by(Field, name: name)


end



