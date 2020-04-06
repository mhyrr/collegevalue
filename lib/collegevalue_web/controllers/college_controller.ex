defmodule CollegevalueWeb.CollegeController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.College

  def index(conn, params) do
    page = params["page"] || 1
    # per_page = params["per_page"] || 100

    colleges = Colleges.list_colleges(:paged, page)
    render(conn, "index.html", colleges: colleges)
  end

  def rank(conn, %{"rank" => ranking, "count" => count}) do
    IO.inspect(ranking)

    ranks = case ranking do
      "top_college_debt_to_earnings" ->
        Colleges.get_colleges_by_costs(:debt_median, :earnings_median_after10, :top, count)
      "bottom_college_debt_to_earnings" ->
        Colleges.get_colleges_by_costs(:debt_median, :earnings_median_after10, :bottom, count)
      "top_college_graddebt_to_earnings" ->
        Colleges.get_colleges_by_costs(:graduated_debt_median, :earnings_median_after10, :top, count)
      "bottom_college_graddebt_to_earnings" ->
        Colleges.get_colleges_by_costs(:graduated_debt_median, :earnings_median_after10, :bottom, count)
      "top_college_yearly_earnings" ->
        Colleges.get_colleges_by_costs(:yearly_cost, :earnings_median_after10, :top, count)
      "bottom_college_yearly_earnings" ->
        Colleges.get_colleges_by_costs(:yearly_cost, :earnings_median_after10, :bottom, count)
    end

    render(conn, "rank.html", ranks: ranks)
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Colleges.get_colleges_by_costs)
  end

  def show(conn, %{"name" => name}) do
    IO.inspect("show!!")
    college = Colleges.get_college_by_name!(URI.decode(name))
    majors = Colleges.get_majors_by_college(college.name)

    render(conn, "show.html", college: college, majors: majors)
  end



end
