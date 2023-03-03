
defmodule CollegevalueWeb.CollegesLive.Matches do
  use Phoenix.LiveView

  alias Collegevalue.{Fields, Colleges}

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.CollegeView, "matches.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, %{"colleges" => colleges, "stretch" => stretch}, socket) do

    # college = Colleges.get_colleges_by_college(name)
    # colleges = Colleges.get_colleges_by_college(name)

    # toggle_cred = case Enum.filter(colleges, fn m -> m.credential_level == 3 end) |> length == 0 do
    #   true ->
    #     true
    #   false ->
    #     false
    # end

    {:ok, assign(socket, colleges: colleges, stretch: stretch, order: "desc")}
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

  #   colleges = case sort_by do
  #     sort_by when sort_by in ~w(name credential debt_mean debt_median earnings) ->
  #       Colleges.get_colleges_by_college(college.name) |> sort_colleges(sort_by) |> handle_direction(sort_order)
  #     _ ->
  #       Colleges.get_colleges_by_college(college.name)
  #   end

  #   {:noreply, socket |> assign(college: college) |> assign(colleges: colleges) |> assign(order: sort_order)}
  # end

  # @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  # def handle_params(%{"name" => name}, _url, socket) do
  #   college = Colleges.get_college_by_name!(URI.decode(name))
  #   colleges = Colleges.get_colleges_by_college(college.name)

  #   {:noreply, socket |> assign(college: college) |> assign(colleges: colleges)}
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

    colleges = socket.assigns.colleges |> sort_colleges(sort) |> handle_direction(sort_order, sort)
    {:noreply, socket |> assign(colleges: colleges) |> assign(order: sort_order)}

  end


  def handle_event("sort_stretch", %{"sort" => sort}, socket) do

    sort_order = case socket.assigns.order do
      "desc" ->
        "asc"
      "asc" ->
        "desc"
      _ ->
        "desc"
    end

    stretch = socket.assigns.stretch |> sort_colleges(sort) |> handle_direction(sort_order, sort)
    {:noreply, socket |> assign(stretch: stretch) |> assign(order: sort_order)}

  end

  def handle_direction(colleges, order, sort_by) do
    case order do
      "desc" ->
        Enum.reverse(colleges) |> trailing_data(sort_by)
      _ ->
        colleges |> trailing_data(sort_by)
    end
  end

  def trailing_data(colleges, sort_by) do
    {no_data, data} = colleges
    |> Enum.split_with( fn x ->
      Map.get(x, String.to_existing_atom(sort_by)) == -1
    end)

    Enum.concat(data, no_data)

  end

  def sort_colleges(colleges, "name") do
    colleges
    |> Enum.sort_by(fn college  -> college.name end)
  end


  def sort_colleges(colleges, "admissions") do
    colleges
    |> Enum.sort_by(fn college  -> college.admissions_rate end)
  end

  def sort_colleges(colleges, "debt_median") do
    colleges
    |> Enum.map( fn x ->
      case Map.get(x, :debt_median) do
        nil ->
          Map.put(x, :debt_median, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn college  -> college.debt_median end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_colleges(colleges, "difference") do
    colleges
    |> Enum.map( fn x ->
      case Map.get(x, :debt_median) do
        nil ->
          Map.put(x, :debt_median, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn college  -> (college.earnings_median_after10 - college.debt_median) end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_colleges(colleges, "sat") do
    colleges
    |> Enum.sort_by(fn college  -> college.sat_avg end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_colleges(colleges, "earnings") do
    colleges
    |> Enum.map( fn x ->
      case Map.get(x, :earnings_median_after10) do
        nil ->
          Map.put(x, :earnings_median_after10, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn college  -> college.earnings_median_after10 end, &Decimal.cmp(&1, &2) != :lt)
  end



end
