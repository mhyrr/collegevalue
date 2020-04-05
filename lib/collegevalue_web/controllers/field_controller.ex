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
    IO.inspect(ranking)

    ranks = case ranking do
      "top_debt_to_earnings" ->
        Fields.get_bachelors_debt_earnings("top", count)
      "bottom_debt_to_earnings" ->
        Fields.get_bachelors_debt_earnings("bottom", count)
    end

    render(conn, "rank.html", ranks: ranks)
  end

  def rank(conn, _params) do
    render(conn, "rank.html", ranks: Fields.get_bachelors_debt_earnings)
  end


end
