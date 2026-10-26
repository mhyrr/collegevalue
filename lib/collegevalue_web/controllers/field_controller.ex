defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Fields, Colleges}

  @rank_description "Bachelor's programs ranked college by college on how many months of first-year pay it takes to clear the student-loan debt, or on earnings alone."




  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    field = Fields.get_field!(name)
    majors = Colleges.get_majors_by_field(field.name)

    render(conn, "show.html", field: field, majors: majors, page_title: name)
  end


  def you(conn, %{"zip" => zip, "distance" => distance, "sat" => sat, "major" => major}) do


    discs = Fields.list_fields() |> Enum.filter( fn major -> major.count > 50 end) |> Enum.map( fn major -> major.name end)

    if Collegevalue.Location.get_location(zip) == "couldn't get lat/long from zip" do
      render(conn, "you.html",discs: discs, majors: [], stretch: [], page_title: "Matches For You" , zipmsg: "Enter a valid Zip!!")
    end

    IO.inspect("majors")
    IO.inspect(major)

    majors = []

    majors = major
    |> Enum.map( fn m ->
      majors = [ Colleges.find_good_majors(zip, String.to_integer(distance), m) | majors]
      end)
    |> List.flatten
    IO.inspect(List.flatten(majors))

    case sat do
      nil ->
        render(conn, "you.html",discs: discs, majors: majors, stretch: [], page_title: "Matches For You", zipmsg: "")
      "" ->
        render(conn, "you.html", discs: discs, majors: majors, stretch: [], page_title: "Matches For You", zipmsg: "")
      _ ->

        score = String.to_integer(sat)
        majors = []

        majors = major
        |> Enum.map( fn m ->
          majors = [ Colleges.find_good_majors(zip, score - 150, score + 70, String.to_integer(distance), m) | majors]
          end)
        |> List.flatten
        IO.inspect(List.flatten(majors))

        stretch = []
        stretch = major
        |> Enum.map( fn m ->
          stretch = [ Colleges.find_good_majors(zip, score + 70, score + 200, String.to_integer(distance), m) | stretch]
          end)
        |> List.flatten
        render(conn, "you.html", discs: discs, majors: majors,
          stretch: stretch, page_title: "Matches For You", zipmsg: "")
    end

  end

  def you(conn, _params) do


    discs = Fields.list_fields() |> Enum.filter( fn major -> major.count > 50 end) |> Enum.map( fn major -> major.name end)

    IO.inspect("base")
    render(conn, "you.html", discs: discs, majors: [], stretch: [], page_title: "Ranked Majors", zipmsg: "")
  end


  # The old debt-to-earnings ranking keys still work, as the repayment
  # ranking that replaced them.
  def rank(conn, %{"rank" => ranking, "count" => count} = params) do
    require_debt = params["require_debt"] == "true"
    opts = [require_debt: require_debt]

    {ranking, ranks} = case ranking do
      r when r in ["slowest_repay", "bottom_debt_to_earnings"] ->
        {"slowest_repay", Fields.get_bachelors_months_to_repay("slowest", count)}
      "top_earnings" ->
        {"top_earnings", Fields.get_bachelors_earnings("top", count, opts)}
      "bottom_earnings" ->
        {"bottom_earnings", Fields.get_bachelors_earnings("bottom", count, opts)}
      _ ->
        {"fastest_repay", Fields.get_bachelors_months_to_repay("fastest", count)}
    end

    render_rank(conn, ranks, ranking, require_debt)
  end

  def rank(conn, _params) do
    render_rank(conn, Fields.get_bachelors_months_to_repay("fastest", 100), "fastest_repay", false)
  end

  defp render_rank(conn, ranks, ranking, require_debt) do
    render(conn, "rank.html", ranks: ranks, ranking: ranking, require_debt: require_debt, page_title: "College Majors Ranked by Earnings vs. Debt", meta_description: @rank_description)
  end


end
