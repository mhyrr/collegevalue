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
      "top_college_debt_to_earnings" ->
        Rankings.get_colleges_by_costs(:debt_median, :earnings_median_after10, :top, count)
      "bottom_college_debt_to_earnings" ->
        Rankings.get_colleges_by_costs(:debt_median, :earnings_median_after10, :bottom, count)
      "top_college_graddebt_to_earnings" ->
        Rankings.get_colleges_by_costs(:graduated_debt_median, :earnings_median_after10, :top, count)
      "bottom_college_graddebt_to_earnings" ->
        Rankings.get_colleges_by_costs(:graduated_debt_median, :earnings_median_after10, :bottom, count)
      "top_college_yearly_earnings" ->
        Rankings.get_colleges_by_costs(:yearly_cost, :earnings_median_after10, :top, count)
      "bottom_college_yearly_earnings" ->
        Rankings.get_colleges_by_costs(:yearly_cost, :earnings_median_after10, :bottom, count)
    end

    render(conn, "index.html", ranks: ranks)
  end

  def index(conn, _params) do
    render(conn, "index.html", ranks: Rankings.get_bachelors_debt_earnings)
  end

end
