defmodule CollegevalueWeb.CollegesLive.Show do
  use Phoenix.LiveView

  alias Collegevalue.{Fields, Colleges}

  @cred_all_label "Show All Degrees"
  @cred_bach_only "Bachelor's Only"

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.CollegeView, "majors.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, %{"college" => name}, socket) do

    college = Colleges.get_majors_by_college(name)
    majors = Colleges.get_majors_by_college(name)

    toggle_cred = case Enum.filter(majors, fn m -> m.credential_level == 3 end) |> length == 0 do
      true ->
        true
      false ->
        false
    end

    {:ok, assign(socket, college: college, majors: majors, cred_label: @cred_all_label, toggle_cred: toggle_cred, order: "desc")}
  end


  # @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  # def handle_params(%{"name" => name, "sort_by" => sort_by}, _url, socket) do
  #   college = Colleges.get_college_by_name!(URI.decode(name))

  #   sort_order = case socket.assigns.order do
  #     "desc" ->
  #       "asc"
  #     "asc" ->
  #       "desc"
  #     _ ->
  #       "desc"
  #   end

  #   majors = case sort_by do
  #     sort_by when sort_by in ~w(name credential debt_mean debt_median earnings) ->
  #       Colleges.get_majors_by_college(college.name) |> sort_majors(sort_by) |> handle_direction(sort_order)
  #     _ ->
  #       Colleges.get_majors_by_college(college.name)
  #   end

  #   {:noreply, socket |> assign(college: college) |> assign(majors: majors) |> assign(order: sort_order)}
  # end

  # @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  # def handle_params(%{"name" => name}, _url, socket) do
  #   college = Colleges.get_college_by_name!(URI.decode(name))
  #   majors = Colleges.get_majors_by_college(college.name)

  #   {:noreply, socket |> assign(college: college) |> assign(majors: majors)}
  # end

  def handle_event("sort", %{"sort" => sort}, socket) do

    sort_order = case socket.assigns.order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "desc"
    end

    majors = socket.assigns.majors |> sort_majors(sort) |> handle_direction(sort_order, sort)
    {:noreply, socket |> assign(majors: majors) |> assign(order: sort_order)}

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


  def handle_direction(majors, order, sort_by) do
    case order do
      "desc" ->
        Enum.reverse(majors) |> trailing_data(sort_by)
      _ ->
        majors |> trailing_data(sort_by)
    end
  end

  def trailing_data(majors, sort_by) do
    {no_data, data} = majors
    |> Enum.split_with( fn x ->
      Map.get(x, String.to_existing_atom(sort_by)) == -1
    end)

    Enum.concat(data, no_data)

  end

  def sort_majors(majors, "name") do
    majors
    |> Enum.sort_by(fn major  -> major.name end)
  end


  def sort_majors(majors, "credential_level") do
    majors
    |> Enum.sort_by(fn major  -> major.credential_level end)
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
