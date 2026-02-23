
defmodule CollegevalueWeb.FieldsLive.Matches do
  use Phoenix.LiveView

  alias Collegevalue.{Fields, Colleges}

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "matches.html", assigns)
  end

  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, %{"majors" => majors, "stretch" => stretch}, socket) do

    # college = majors.get_majors_by_college(name)
    # majors = majors.get_majors_by_college(name)

    # toggle_cred = case Enum.filter(majors, fn m -> m.credential_level == 3 end) |> length == 0 do
    #   true ->
    #     true
    #   false ->
    #     false
    # end

    {:ok, assign(socket, majors: sort_majors(majors, "earnings1yr"), stretch: sort_majors(stretch, "earnings1yr"), order: "desc", sort_by: "earnings1yr")}
  end


  # @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  # def handle_params(%{"name" => name, "sort_by" => sort_by}, _url, socket) do
  #   college = majors.get_college_by_name!(URI.decode(name))

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

  #   {:noreply, socket |> assign(college: college) |> assign(colleges: majors) |> assign(order: sort_order)}
  # end

  # @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) :: {:noreply, any}
  # def handle_params(%{"name" => name}, _url, socket) do
  #   college = majors.get_college_by_name!(URI.decode(name))
  #   majors = majors.get_majors_by_college(college.name)

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
    {:noreply, socket |> assign(majors: majors) |> assign(order: sort_order) |> assign(sort_by: sort)}

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

    stretch = socket.assigns.stretch |> sort_majors(sort) |> handle_direction(sort_order, sort)
    {:noreply, socket |> assign(stretch: stretch) |> assign(order: sort_order) |> assign(sort_by: sort)}

  end

  def handle_direction(majors, order, sort_by) do
    case order do
      "desc" ->
        Enum.reverse(majors) # |> trailing_data(sort_by)
      _ ->
        majors # |> trailing_data(sort_by)
    end
  end

  def trailing_data(majors, sort_by) do
    {no_data, data} = majors
    |> Enum.split_with( fn x ->
      Map.get(x, String.to_existing_atom(sort_by)) == -1
    end)

    Enum.concat(data, no_data)

  end

  def sort_majors(majors, "major") do
    majors
    |> Enum.sort_by(fn m  -> m.name end)
  end

  def sort_majors(majors, "name") do
    majors
    |> Enum.sort_by(fn m  -> m.college.name end)
  end


  def sort_majors(majors, "admissions") do
    majors
    |> Enum.sort_by(fn m -> m.college.admissions_rate end)
  end

  def sort_majors(majors, "debt_median") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :pp_debt_median) do
        nil ->
          Map.put(x, :pp_debt_median, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn m  -> m.pp_debt_median end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "college_debt_median") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x.college, :debt_median) do
        nil ->
          Map.put(x.college, :debt_median, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn m  -> m.college.debt_median end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "sat") do
    majors
    |> Enum.sort_by(fn m  -> m.college.sat_avg end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "earnings10yr") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :earnings_median_after10) do
        nil ->
          Map.put(x, :earnings_median_after10, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn m  -> m.college.earnings_median_after10 end, &Decimal.cmp(&1, &2) != :lt)
  end


  def sort_majors(majors, "earnings1yr") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :earnings_median_1) do
        nil ->
          Map.put(x, :earnings_median_1, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn m  -> m.earnings_1yr end, &Decimal.cmp(&1, &2) != :lt)
  end

  def sort_majors(majors, "earnings2yr") do
    majors
    |> Enum.map( fn x ->
      case Map.get(x, :earnings_median_2) do
        nil ->
          Map.put(x, :earnings_median_2, 0)
        _ ->
          x
      end
    end)
    |> Enum.sort_by(fn m  -> m.earnings_2yr end, &Decimal.cmp(&1, &2) != :lt)
  end



end
