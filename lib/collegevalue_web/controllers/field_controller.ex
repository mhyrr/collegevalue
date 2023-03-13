defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Fields, Colleges}




  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    field = Fields.get_field!(name)
    majors = Colleges.get_majors_by_field(field.name)

    render(conn, "show.html", field: field, majors: majors, page_title: name)
  end


  def you(conn, %{"zip" => zip, "distance" => distance, "sat" => sat, "major" => major}) do


    discs = Fields.list_fields() |> Enum.filter( fn major -> major.count > 50 end) |> Enum.map( fn major -> major.name end)

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
        render(conn, "you.html",discs: @discs, majors: majors, stretch: [], page_title: "Matches For You")
      "" ->
        render(conn, "you.html", discs: @discs, majors: majors, stretch: [], page_title: "Matches For You")
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
          stretch: stretch, page_title: "Matches For You")
    end

  end

  def you(conn, _params) do


    discs = Fields.list_fields() |> Enum.filter( fn major -> major.count > 50 end) |> Enum.map( fn major -> major.name end)

    IO.inspect("base")
    render(conn, "you.html", discs: discs, majors: [], stretch: [], page_title: "Ranked Majors")
  end


  def rank(conn, %{"rank" => ranking, "count" => count}) do

    ranks = case ranking do
      "top_debt_to_earnings" ->
        Fields.get_bachelors_debt_earnings("top", count)
      "bottom_debt_to_earnings" ->
        Fields.get_bachelors_debt_earnings("bottom", count)
      "top_earnings" ->
        Fields.get_bachelors_earnings("top", count)
      "bottom_earnings" ->
        Fields.get_bachelors_earnings("bottom", count)
    end

    render(conn, "rank.html", ranks: ranks, ranking: ranking, page_title: "Ranked Fields")
  end

  def rank(conn, %{}) do
    render(conn, "rank.html", ranks: Fields.get_bachelors_debt_earnings("top", 100), ranking: "top_debt_to_earnings", page_title: "Ranked Fields")
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Fields.get_bachelors_debt_earnings, page_title: "Ranked Fields" )
  end


end
