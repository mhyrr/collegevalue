defmodule CollegevalueWeb.FieldsLive.Show do
  use Phoenix.LiveView
  import Logger

  alias Collegevalue.{Fields, Colleges}
  alias Collegevalue.FieldNotes
  alias Collegevalue.FieldNotes.Facts
  alias CollegevalueWeb.Router.Helpers, as: Routes
  import CollegevalueWeb.Views.Helpers, only: [field_title: 1, field_page_path: 2]

  @cred_all_label "Show All Degrees"
  @cred_bach_only "Bachelor's Only"
  @amounts ~w(debt_mean debt_median earnings)

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

    field = Fields.get_field_by_slug!(name)

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

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.has_outcomes?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(order: sort_order) |> assign(show_all: show_all) |> assign(sort_by: sort_by) |> assign_rows()}
  end

  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name, "sort_by" => sort_by}, _url, socket) do

    Logger.debug("handle params 2")

    field = Fields.get_field_by_slug!(name)

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

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.has_outcomes?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(order: sort_order) |> assign(sort_by: sort_by) |> assign_rows()}
  end


  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name}, _url, socket) do
    Logger.debug("handle params 1")

    field = Fields.get_field_by_slug!(name)
    majors = Colleges.get_majors_by_field(field.name)
      |> sort_majors("earnings")
      |> handle_direction("desc", "earnings")

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.has_outcomes?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(sort_by: "earnings") |> assign(order: "desc") |> assign_rows()}
  end


  def handle_event("toggle_credentials", _value, socket) do

    Logger.debug("toggling creds")
    # Logger.debug(@field.name)
    # IO.inspect(socket.assigns)

    show_all = !socket.assigns.show_all
    cred_label = if (show_all == true), do: "Bachelor's Only", else: "Show All Degrees"

    # {:noreply, socket |> assign(show_all: show_all) |> assign(cred_label: cred_label)}

    {:noreply, push_patch(socket |> assign(show_all: show_all) |> assign(cred_label: cred_label),
      to: field_page_path(socket.assigns.field.name, %{show_all: show_all}))}

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

  # Scorecard marks a missing number -1 and a privacy-suppressed one -2, so
  # anything not positive sorts after the real numbers in either direction.
  def trailing_data(majors, sort_by) when sort_by in @amounts do
    {data, no_data} = Enum.split_with(majors, &data?(Map.get(&1, String.to_existing_atom(sort_by))))
    data ++ no_data
  end

  def trailing_data(majors, _sort_by), do: majors

  def sort_majors(majors, "name"), do: Enum.sort_by(majors, & &1.college_name)
  def sort_majors(majors, "credential_level"), do: Enum.sort_by(majors, & &1.credential_level)
  def sort_majors(majors, sort_by), do: Enum.sort_by(majors, &(Map.get(&1, String.to_existing_atom(sort_by)) || -3))

  # The table hides programs with no debt or earnings at all and counts them instead.
  defp assign_rows(%{assigns: assigns} = socket) do
    shown = Enum.filter(assigns.majors, &(show_all?(assigns.show_all) or &1.credential_level == 3))
    {rows, empty} = Enum.split_with(shown, fn major -> Enum.any?([major.debt_mean, major.debt_median, major.earnings], &data?/1) end)
    assign(socket, rows: rows, no_data_count: length(empty))
  end

  defp show_all?(show_all), do: show_all in [true, "true"]

  defp data?(value), do: is_integer(value) and value > 0

  # Sorting patches the URL and reruns handle_params; the facts only depend on
  # the field, so they are computed once per field.
  defp assign_facts(%{assigns: %{facts: %{name: name}}} = socket, %{name: name}, _majors), do: socket
  defp assign_facts(socket, field, majors) do
    colleges = Enum.map(majors, &{&1.college_name, &1.unit_id})
    note = field.name |> FieldNotes.approved_paragraphs() |> FieldNotes.link_colleges(colleges)
    assign(socket, facts: Facts.for_field(field.name), note: note)
  end
end
