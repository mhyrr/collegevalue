defmodule CollegevalueWeb.RankController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Rankings
  alias Collegevalue.Rankings.Rank

  def index(conn, %{"rank" => ranking, "count" => count}) do
    IO.inspect(ranking)

    ranks = case ranking do
      "top_debt_to_earnings" ->
        Rankings.get_bachelors_debt_earnings("top", count)
      "bottom_debt_to_earnings" ->
        Rankings.get_bachelors_debt_earnings("bottom", count)
    end

    render(conn, "index.html", ranks: ranks)
  end

  def index(conn, _params) do
    render(conn, "index.html", ranks: Rankings.get_bachelors_debt_earnings)
  end

end
