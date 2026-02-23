defmodule CollegevalueWeb.FieldsLive.Show do
  use Phoenix.LiveView
  import Logger

  alias Collegevalue.{Fields, Colleges}
  alias CollegevalueWeb.Router.Helpers, as: Routes

  @cred_all_label "Show All Degrees"
  @cred_bach_only "Bachelor's Only"

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "show.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"order" => order, "show_all" => show_all}, _, socket) do
    {:ok, assign(socket, cred_label: @cred_all_label, show_all: show_all, order: order)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"order" => order}, _, socket) do
    {:ok, assign(socket, cred_label: @cred_all_label, show_all: false, order: order)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"show_all" => show_all}, _, socket) do
    {:ok, assign(socket, cred_label: @cred_all_label, show_all: show_all, order: "desc")}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"show_all" => show_all, "order" => order, "sort_by" => sort_by}, _, socket) do
    # IO.inspect("here it is..")
    {:ok, assign(socket, cred_label: @cred_all_label, show_all: show_all, order: order, sort_by: sort_by)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, _, socket) do
    {:ok, assign(socket, cred_label: @cred_all_label, show_all: false, order: "desc")}
  end


  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name, "sort_by" => sort_by, "show_all" => show_all}, _url, socket) do

    Logger.debug("handle params 3")

    Logger.debug(show_all)

    field = Fields.get_field!(URI.decode(name))

    sort_order = case socket.assigns.order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "desc"
    end

    majors = case sort_by do
      sort_by when sort_by in ~w(name credential_level debt_mean debt_median earnings) ->
        Colleges.get_majors_by_field(field.name) |> sort_majors(sort_by) |> handle_direction(sort_order, sort_by)
      _ ->
        Colleges.get_majors_by_field(field.name)
    end

    {:noreply, socket |> assign(field: field) |> assign(majors: majors) |> assign(order: sort_order) |> assign(show_all: show_all) |> assign(sort_by: sort_by)}
  end

  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name, "sort_by" => sort_by}, _url, socket) do

    Logger.debug("handle params 2")

    field = Fields.get_field!(URI.decode(name))

    sort_order = case socket.assigns.order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "desc"
    end

    majors = case sort_by do
      sort_by when sort_by in ~w(name credential_level debt_mean debt_median earnings) ->
        Colleges.get_majors_by_field(field.name) |> sort_majors(sort_by) |> handle_direction(sort_order, sort_by)
      _ ->
        Colleges.get_majors_by_field(field.name)
    end

    {:noreply, socket |> assign(field: field) |> assign(majors: majors) |> assign(order: sort_order) |> assign(sort_by: sort_by)}
  end


  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name}, _url, socket) do
    Logger.debug("handle params 1")

    field = Fields.get_field!(URI.decode(name))
    majors = Colleges.get_majors_by_field(field.name)

    {:noreply, socket |> assign(field: field) |> assign(majors: majors) |> assign(sort_by: nil)}
  end


  def handle_event("toggle_credentials", _value, socket) do

    Logger.debug("toggling creds")
    # Logger.debug(@field.name)
    # IO.inspect(socket.assigns)

    show_all = !socket.assigns.show_all
    cred_label = if (show_all == true), do: "Bachelor's Only", else: "Show All Degrees"

    # {:noreply, socket |> assign(show_all: show_all) |> assign(cred_label: cred_label)}

    {:noreply, push_patch(socket |> assign(show_all: show_all) |> assign(cred_label: cred_label),
      to: Routes.live_path(socket, CollegevalueWeb.FieldsLive.Show, socket.assigns.field.name, %{show_all: show_all}))}

  end

  def handle_direction(majors, order, sort_by) do
    case order do
      "desc" ->
        Enum.reverse(majors)
      _ ->
        majors
    end
    |> trailing_data(sort_by)

  end

  def trailing_data(fields, sort_by) do

    {no_data, data} = fields
    |> Enum.split_with( fn x ->
      Map.get(x, String.to_existing_atom(sort_by)) == -1
    end)

    Enum.concat(data, no_data)

  end


  def sort_majors(majors, "name") do
    majors
    |> Enum.sort_by(fn major  -> major.college_name end)
  end


  def sort_majors(majors, "credential_level") do
    majors
    |> Enum.sort_by(fn major ->IO.inspect(major); major.credential_level end)
  end

  def sort_majors(majors, "debt_mean") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :debt_avg) do
        nil ->
          Map.put(x, :debt_avg, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn major  -> major.debt_mean end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "debt_median") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :debt_min) do
        nil ->
          Map.put(x, :debt_min, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn major  -> major.debt_median end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "earnings") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :earn_min) do
        nil ->
          Map.put(x, :earn_min, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn major  -> major.earnings end, &Decimal.cmp(&1, &2) != :lt)
  end



end
