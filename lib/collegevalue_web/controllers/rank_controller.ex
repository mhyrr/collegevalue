defmodule CollegevalueWeb.RankController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Rankings
  alias Collegevalue.Rankings.Rank

  def index(conn, _params) do
    ranks = Rankings.get_top_bachelors_debt_earnings


    render(conn, "index.html", ranks: ranks)
  end

end
