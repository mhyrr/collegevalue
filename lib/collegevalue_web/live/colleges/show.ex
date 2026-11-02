defmodule CollegevalueWeb.CollegesLive.Show do
  use Phoenix.LiveView

  alias Collegevalue.Colleges
  alias CollegevalueWeb.ProgramTable

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.CollegeView, "majors.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, %{"college" => name}, socket) do
    majors = name |> Colleges.get_majors_by_college() |> ProgramTable.sort("earnings", "desc", :name)
    # A college with no bachelor's programs opens on everything it offers.
    show_all = not Enum.any?(majors, &(&1.credential_level == 3))

    {:ok, socket |> assign(majors: majors, sort_by: "earnings", order: "desc", show_all: show_all) |> assign_rows()}
  end

  def handle_event("sort", %{"sort" => sort_by}, socket) do
    if sort_by in ProgramTable.sorts() do
      %{sort_by: current, order: order} = socket.assigns
      order = cond do
        sort_by != current -> ProgramTable.first_order(sort_by)
        order == "desc" -> "asc"
        true -> "desc"
      end

      majors = ProgramTable.sort(socket.assigns.majors, sort_by, order, :name)
      {:noreply, socket |> assign(majors: majors, sort_by: sort_by, order: order) |> assign_rows()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("credentials", %{"show" => show}, socket) do
    {:noreply, socket |> assign(show_all: show == "all") |> assign_rows()}
  end

  defp assign_rows(socket), do: assign(socket, ProgramTable.rows(socket.assigns.majors, socket.assigns.show_all))
end
