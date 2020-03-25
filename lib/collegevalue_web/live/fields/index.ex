defmodule CollegevalueWeb.FieldsLive.Index do
  use Phoenix.LiveView

  alias Collegevalue.Fields
  alias Collegevalue.Fields.Field

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "index.html", assigns)
  end

  def mount(_, socket) do
    sort_order = "asc"
    fields = Fields.list_fields()
    {:ok, assign(socket, fields: fields, order: sort_order)}
  end

  @spec handle_params(any, any, any) :: {:noreply, any}
  def handle_params(%{"sort_by" => sort_by}, _uri, socket) do

    sort_order = case socket.assigns.order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "asc"
    end

    IO.inspect(socket)

    case sort_by do
      sort_by when sort_by in ~w(name count debt_avg debt_min debt_max earn_max earn_avg earn_min) ->
        {:noreply, assign(socket, order: sort_order, fields: sort_fields(socket.assigns.fields, sort_by) |> handle_direction(sort_order) )}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_direction(fields, order) do
    case order do
      "desc" ->
        Enum.reverse(fields)
      _ ->
        fields
    end
  end

  def sort_fields(fields, "name") do
    fields
    |> Enum.sort_by(fn field  -> field.name end)
  end


  def sort_fields(fields, "count") do
    fields
    |> Enum.sort_by(fn field  -> field.count end)
  end

  def sort_fields(fields, "debt_avg") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :debt_avg) do
        nil ->
          Map.put(x, :debt_avg, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.debt_avg end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_fields(fields, "debt_min") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :debt_min) do
        nil ->
          Map.put(x, :debt_min, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.debt_min end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_fields(fields, "debt_max") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :debt_max) do
        nil ->
          Map.put(x, :debt_max, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.debt_max end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_fields(fields, "earn_avg") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :earn_avg) do
        nil ->
          Map.put(x, :earn_avg, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.earn_avg end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_fields(fields, "earn_min") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :earn_min) do
        nil ->
          Map.put(x, :earn_min, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.earn_min end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_fields(fields, "earn_max") do
    fields
    |> Enum.map( fn x ->
      case Map.get(x, :earn_max) do
        nil ->
          Map.put(x, :earn_max, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn field  -> field.earn_max end, &Decimal.cmp(&1, &2) != :lt)
  end

end

