defmodule CollegevalueWeb.CollegeController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.College

  def index(conn, params) do
    page = params["page"] || 1
    # per_page = params["per_page"] || 100

    colleges = Colleges.list_colleges(:paged, page)
    render(conn, "index.html", colleges: colleges, page_title: "All Colleges")
  end


  def you(conn, %{"zip" => zip, "distance" => distance, "sat" => sat}) do

    case sat do
      nil ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), page_title: "Matches For You")
      "" ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), page_title: "Matches For You")
      _ ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance), String.to_integer(sat)), page_title: "Matches For You")
    end

  end


  def you(conn, _params) do
    render(conn, "you.html", colleges: [], page_title: "Ranked Colleges")
  end

  def rank(conn, %{"rank" => ranking, "count" => count}) do

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

    render(conn, "rank.html", ranks: ranks, page_title: "Ranked Colleges")
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Colleges.get_colleges_by_costs, page_title: "Ranked Colleges")
  end

  def show(conn, %{"name" => name, "unitid" => unitid}) do

    college = Colleges.get_college_by_name_and_unitid!(URI.decode(name), unitid)
    majors = Colleges.get_majors_by_college(college.name)

    render(conn, "show.html", college: college, majors: majors, page_title: name)
  end



end
