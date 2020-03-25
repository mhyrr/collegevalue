defmodule CollegevalueWeb.FieldsLive.Show do
  use Phoenix.LiveView

  alias Collegevalue.{Fields, Colleges}

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "show.html", assigns)
  end

  @spec mount(any, any) :: {:ok, any}
  def mount(_, socket) do
    cred_label = "Show All Degrees"
    toggle_cred = false;
    {:ok, assign(socket, cred_label: cred_label, toggle_cred: toggle_cred)}
  end

  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  def handle_params(%{"name" => name}, _url, socket) do

    field = Fields.get_field!(URI.decode(name))
    # IO.inspect(name)

    majors = Colleges.get_by_field(field.name)

    IO.inspect(majors)

    {:noreply, socket |> assign(field: field) |> assign(majors: majors)}

  end

  def handle_event("toggle_credentials", _value, socket) do

    toggle_cred = !socket.assigns.toggle_cred
    cred_label = if (toggle_cred == true), do: "Bachelor's Only", else: "Show All Degrees"

    new_socket =
      socket
      |> assign(toggle_cred: toggle_cred)
      |> assign(cred_label: cred_label)

    {:noreply, new_socket}

  end


end
