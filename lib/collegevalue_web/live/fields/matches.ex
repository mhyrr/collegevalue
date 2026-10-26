
defmodule CollegevalueWeb.FieldsLive.Matches do
  use Phoenix.LiveView

  alias Collegevalue.{Fields, Colleges}

  def render(assigns) do
    Phoenix.View.render(CollegevalueWeb.FieldView, "matches.html", assigns)
  end

  # `income` is the bracket from the income cookie. With `all_majors`, the
  # matches span every major and arrive fastest to repay first.
  @spec mount(any, any, any) :: {:ok, any}
  def mount(_, %{"majors" => majors, "stretch" => stretch} = session, socket) do
    all_majors = Map.get(session, "all_majors", false)
    sort_by = if all_majors, do: "months", else: "earnings1yr"
    order = if all_majors, do: "asc", else: "desc"

    {:ok, assign(socket, majors: sort_majors(majors, sort_by), stretch: sort_majors(stretch, sort_by), order: order,
      sort_by: sort_by, all_majors: all_majors, income: Fields.income_bracket(Map.get(session, "income")))}
  end

  # The family-income bracket for the cost columns; invalid values mean 3.
  # The browser keeps the choice in the income cookie for the other pages.
  def handle_event("income", %{"income" => income}, socket) do
    income = Fields.income_bracket(income)
    {:noreply, socket |> assign(income: income) |> push_event("remember_income", %{income: income})}
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

    majors = socket.assigns.majors |> sort_majors(sort, socket.assigns.income) |> handle_direction(sort_order, sort)
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

    stretch = socket.assigns.stretch |> sort_majors(sort, socket.assigns.income) |> handle_direction(sort_order, sort)
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

  # The cost and value sorts depend on the family-income bracket.
  # Four-year net price, most expensive first; schools without one last.
  def sort_majors(majors, "cost", income) do
    Enum.sort_by(majors, fn m -> Fields.net_price(m.college, income) || 0 end, :desc)
  end

  # Fewest years of pay to cover the cost first; programs without a figure last.
  def sort_majors(majors, "value", income) do
    Enum.sort_by(majors, fn m -> CollegevalueWeb.Views.Helpers.program_value_years(m, income) || 1.0e9 end)
  end

  def sort_majors(majors, sort, _income), do: sort_majors(majors, sort)

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

  # The program's median student-loan debt; missing figures (stored as -1 or
  # -2) sort as 0.
  def sort_majors(majors, "debt_median") do
    Enum.sort_by(majors, fn m -> max(m.stgp_debt_median || 0, 0) end, :desc)
  end

  # Fewest months to repay first; programs without a figure last.
  def sort_majors(majors, "months") do
    Enum.sort_by(majors, fn m -> CollegevalueWeb.Views.Helpers.program_months(m) || 1.0e9 end)
  end

  def sort_majors(majors, "tuition") do
    Enum.sort_by(majors, fn m -> max(m.college.tuition_in || 0, 0) end, :desc)
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
