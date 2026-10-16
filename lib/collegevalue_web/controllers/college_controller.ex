defmodule CollegevalueWeb.CollegeController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields

  import CollegevalueWeb.Views.Helpers, only: [college_title: 1]

  @index_description "Every college in the College Scorecard data, with its location, control and accreditation. Open one for its costs, debt, completion rates and earnings."
  @rank_description "Colleges ranked by yearly cost, median debt and graduates' median debt against median earnings 10 years out, top and bottom."

  def index(conn, params) do
    page = params["page"] || 1
    # per_page = params["per_page"] || 100

    colleges = Colleges.list_colleges(:paged, page)

    {title, description} =
      if colleges.page > 1 do
        {"All Colleges, #{colleges.first}–#{colleges.last}",
         "Colleges #{colleges.first} to #{colleges.last} of #{colleges.count} in the College Scorecard data, A to Z, with location, control and accreditation."}
      else
        {"All Colleges", @index_description}
      end

    render(conn, "index.html", colleges: colleges, page_title: title, meta_description: description)
  end


  # def you(conn, %{"zip" => zip, "distance" => distance, "sat" => sat, "major" => major}) do

  #   IO.inspect("majors")
  #   IO.inspect(major)

  #   m = Enum.at(major, 0)

  #   case sat do
  #     nil ->
  #       render(conn, "you.html", majors: @majors, colleges: [], discs: Colleges.find_good_majors(zip, String.to_integer(distance), m), stretch: [], page_title: "Matches For You")
  #     "" ->
  #       render(conn, "you.html", majors: @majors, colleges: [], discs: Colleges.find_good_majors(zip, String.to_integer(distance), m), stretch: [], page_title: "Matches For You")
  #     _ ->
  #       score = String.to_integer(sat)
  #       render(conn, "you.html", majors: @majors, colleges: [], discs: Colleges.find_good_majors(zip, String.to_integer(distance), score - 150, score + 70, m),
  #         stretch: Colleges.find_good_majors(zip, String.to_integer(distance), score + 70, score + 200, m), page_title: "Matches For You")
  #   end


  # end


  def you(conn, %{"zip" => zip, "distance" => distance, "sat" => sat}) do

    if Collegevalue.Location.get_location(zip) == "couldn't get lat/long from zip" do
      render(conn, "you.html", colleges: [], stretch: [], page_title: "Ranked Colleges", zipmsg: "Enter a valid Zip!!")
    end

    case sat do
      nil ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), stretch: [], page_title: "Matches For You", zipmsg: "")
      "" ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), stretch: [], page_title: "Matches For You", zipmsg: "")
      _ ->
        score = String.to_integer(sat)
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance), score - 150, score + 70),
          stretch: Colleges.find_good_colleges(zip, String.to_integer(distance), score + 70, score + 200), page_title: "Matches For You", zipmsg: "")
    end



  end


  def you(conn, _params) do
    IO.inspect("base")
    render(conn, "you.html", colleges: [], stretch: [], page_title: "Ranked Colleges", zipmsg: "")
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

    render(conn, "rank.html", ranks: ranks, page_title: "Ranked Colleges", meta_description: @rank_description)
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Colleges.get_colleges_by_costs, page_title: "Ranked Colleges", meta_description: @rank_description)
  end

  def show(conn, %{"name" => name, "unitid" => unitid}) do

    college = Colleges.get_college_by_name_and_unitid!(URI.decode(name), unitid)
    majors = Colleges.get_majors_by_college(college.name)

    render(conn, "show.html",
      college: college,
      majors: majors,
      page_title: college_title(college),
      noindex: not Colleges.has_outcomes?(college)
    )
  end



end
