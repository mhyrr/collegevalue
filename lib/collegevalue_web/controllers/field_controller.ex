defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Fields, Colleges}

  @income_cookie "cv_income"

  @rank_description "Bachelor's programs ranked college by college on how many months of first-year pay it takes to clear the student-loan debt, on years of pay to cover four years of net price, or on earnings alone."




  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    field = Fields.get_field!(name)
    majors = Colleges.get_majors_by_field(field.name)

    render(conn, "show.html", field: field, majors: majors, page_title: name)
  end


  # With no major picked, the matches are every major near the zip, fastest
  # to repay first. An SAT score splits them into matches (150 below to 70
  # above) and stretch schools (70 to 200 above).
  def you(conn, %{"zip" => zip} = params) do
    distance = parse_int(params["distance"], 25)
    sat = parse_int(params["sat"], nil)
    picked = params |> Map.get("major", []) |> List.wrap() |> Enum.reject(&(&1 == ""))

    if Collegevalue.Location.get_location(zip) == "couldn't get lat/long from zip" do
      render_you(conn, [], [], "Enter a valid Zip!!", picked)
    else
      find = fn range ->
        case picked do
          [] -> Colleges.find_best_majors(zip, distance, range)
          _ -> Enum.flat_map(picked, &find_majors(zip, distance, range, &1))
        end
      end

      case sat do
        nil -> render_you(conn, find.(nil), [], "", picked)
        score -> render_you(conn, find.({score - 150, score + 70}), find.({score + 70, score + 200}), "", picked)
      end
    end
  end

  def you(conn, _params), do: render_you(conn, [], [], "", [])

  defp find_majors(zip, distance, nil, major), do: Colleges.find_good_majors(zip, distance, major)
  defp find_majors(zip, distance, {min, max}, major), do: Colleges.find_good_majors(zip, min, max, distance, major)

  defp render_you(conn, majors, stretch, zipmsg, picked) do
    discs = Fields.list_fields() |> Enum.filter(&(&1.count > 50)) |> Enum.map(& &1.name)
    title = if majors == [] and stretch == [], do: "Ranked Majors", else: "Matches For You"

    render(conn, "you.html", discs: discs, majors: majors, stretch: stretch, page_title: title, zipmsg: zipmsg,
      all_majors: picked == [], income: income(conn, nil))
  end

  defp parse_int(value, default) do
    case Integer.parse(to_string(value)) do
      {int, ""} -> int
      _ -> default
    end
  end


  @rank_counts [10, 50, 100, 250, 500, 1000]

  # The old debt-to-earnings ranking keys still work, as the repayment
  # ranking that replaced them. `income` (1 to 5) picks the family-income
  # bracket for the cost columns; anything else means bracket 3.
  def rank(conn, params) do
    require_debt = params["require_debt"] == "true"
    income = income(conn, params["income"])
    conn = remember_income(conn, params["income"], income)
    count = rank_count(params["count"])
    opts = [require_debt: require_debt, income: income]

    {ranking, ranks} = case params["rank"] do
      r when r in ["slowest_repay", "bottom_debt_to_earnings"] ->
        {"slowest_repay", Fields.get_bachelors_months_to_repay("slowest", count, income)}
      "best_value" ->
        {"best_value", Fields.get_bachelors_value("best", count, income)}
      "worst_value" ->
        {"worst_value", Fields.get_bachelors_value("worst", count, income)}
      "top_earnings" ->
        {"top_earnings", Fields.get_bachelors_earnings("top", count, opts)}
      "bottom_earnings" ->
        {"bottom_earnings", Fields.get_bachelors_earnings("bottom", count, opts)}
      _ ->
        {"fastest_repay", Fields.get_bachelors_months_to_repay("fastest", count, income)}
    end

    render(conn, "rank.html", ranks: ranks, ranking: ranking, require_debt: require_debt, income: income,
      count: count, rank_counts: @rank_counts, page_title: "College Majors Ranked by Earnings vs. Debt",
      meta_description: @rank_description)
  end

  # The family-income bracket comes from the URL, then the income cookie the
  # pages set when someone picks one, then bracket 3.
  defp income(conn, nil), do: Fields.income_bracket(conn.cookies[@income_cookie])
  defp income(_conn, value), do: Fields.income_bracket(value)

  defp remember_income(conn, nil, _income), do: conn
  defp remember_income(conn, _value, income),
    do: put_resp_cookie(conn, @income_cookie, to_string(income), max_age: 365 * 24 * 60 * 60, http_only: false)

  defp rank_count(value) do
    case Integer.parse(to_string(value)) do
      {count, ""} when count in @rank_counts -> count
      _ -> 100
    end
  end



end
