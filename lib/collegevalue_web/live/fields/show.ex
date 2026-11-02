defmodule CollegevalueWeb.FieldsLive.Show do
  use Phoenix.LiveView
  import Logger

  alias Collegevalue.{Fields, Colleges}
  alias Collegevalue.FieldNotes
  alias Collegevalue.FieldNotes.Facts
  alias CollegevalueWeb.ProgramTable
  alias CollegevalueWeb.Router.Helpers, as: Routes
  import CollegevalueWeb.Views.Helpers, only: [field_title: 1, field_page_path: 2]


  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "show.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"order" => order, "show_all" => show_all}, _, socket) do
    {:ok, assign(socket, show_all: show_all, order: order)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"order" => order}, _, socket) do
    {:ok, assign(socket, show_all: false, order: order)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"show_all" => show_all}, _, socket) do
    {:ok, assign(socket, show_all: show_all, order: "desc")}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(%{"show_all" => show_all, "order" => order, "sort_by" => sort_by}, _, socket) do
    # IO.inspect("here it is..")
    {:ok, assign(socket, show_all: show_all, order: order, sort_by: sort_by)}
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, _, socket) do
    {:ok, assign(socket, show_all: false, order: "desc")}
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
        Colleges.get_majors_by_field(field.name) |> ProgramTable.sort(sort_by, sort_order, :college_name)
      _ ->
        Colleges.get_majors_by_field(field.name)
    end

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.indexable?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(order: sort_order) |> assign(show_all: show_all) |> assign(sort_by: sort_by) |> assign_rows()}
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
        Colleges.get_majors_by_field(field.name) |> ProgramTable.sort(sort_by, sort_order, :college_name)
      _ ->
        Colleges.get_majors_by_field(field.name)
    end

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.indexable?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(order: sort_order) |> assign(sort_by: sort_by) |> assign_rows()}
  end


  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name}, _url, socket) do
    Logger.debug("handle params 1")

    field = Fields.get_field_by_slug!(name)
    majors = Colleges.get_majors_by_field(field.name)
      |> ProgramTable.sort("earnings", "desc", :college_name)

    {:noreply, socket |> assign(field: field, page_title: field_title(field), noindex: not Fields.indexable?(field)) |> assign_facts(field, majors) |> assign(majors: majors) |> assign(sort_by: "earnings") |> assign(order: "desc") |> assign_rows()}
  end


  def handle_event("credentials", %{"show" => show}, socket) do
    show_all = show == "all"
    params = if show_all, do: %{show_all: true}, else: %{}

    {:noreply, push_patch(assign(socket, show_all: show_all), to: field_page_path(socket.assigns.field.name, params))}
  end

  # The table hides programs with no debt or earnings at all and counts them instead.
  defp assign_rows(%{assigns: assigns} = socket) do
    show_all = show_all?(assigns.show_all)
    assign(socket, Map.put(ProgramTable.rows(assigns.majors, show_all), :show_all, show_all))
  end

  defp show_all?(show_all), do: show_all in [true, "true"]

  # Sorting patches the URL and reruns handle_params; the facts only depend on
  # the field, so they are computed once per field.
  defp assign_facts(%{assigns: %{facts: %{name: name}}} = socket, %{name: name}, _majors), do: socket
  defp assign_facts(socket, field, majors) do
    colleges = Enum.map(majors, &{&1.college_name, &1.unit_id})
    note = field.name |> FieldNotes.approved_paragraphs() |> FieldNotes.link_colleges(colleges)
    assign(socket, facts: Facts.for_field(field.name), note: note)
  end
end
