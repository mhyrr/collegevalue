defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Fields, Colleges}

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    field = Fields.get_field!(name)
    majors = Colleges.get_majors_by_field(field.name)

    render(conn, "show.html", field: field, majors: majors)
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

    render(conn, "rank.html", ranks: ranks, ranking: ranking)
  end

  def rank(conn, %{}) do
    render(conn, "rank.html", ranks: Fields.get_bachelors_debt_earnings("top", 100), ranking: "top_debt_to_earnings")
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Fields.get_bachelors_debt_earnings)
  end


end
