defmodule CollegevalueWeb.CollegeController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields

  import CollegevalueWeb.Views.Helpers, only: [college_page_title: 2, college_page_path: 2, college_ranking: 1]

  @index_description "Every college in the College Scorecard data, with its location, control and accreditation. Open one for its costs, debt, completion rates and earnings."
  @you_description "Find colleges near you whose graduates earn the most for what they borrow. Enter a zip code, a distance and an SAT score."
  @rank_description "The best and worst value colleges, ranked by what students earn ten years after starting minus what they borrow or pay, with admit and graduation rates for each."

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
      render(conn, "you.html", colleges: [], stretch: [], page_title: "Colleges For You: Best Value Near You", meta_description: @you_description, zipmsg: "Enter a valid Zip!!")
    end

    case sat do
      nil ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), stretch: [], page_title: "Matches For You", meta_description: @you_description, zipmsg: "")
      "" ->
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance)), stretch: [], page_title: "Matches For You", meta_description: @you_description, zipmsg: "")
      _ ->
        score = String.to_integer(sat)
        render(conn, "you.html", colleges: Colleges.find_good_colleges(zip, String.to_integer(distance), score - 150, score + 70),
          stretch: Colleges.find_good_colleges(zip, String.to_integer(distance), score + 70, score + 200), page_title: "Matches For You", meta_description: @you_description, zipmsg: "")
    end



  end


  def you(conn, _params) do
    IO.inspect("base")
    render(conn, "you.html", colleges: [], stretch: [], page_title: "Colleges For You: Best Value Near You", meta_description: @you_description, zipmsg: "")
  end

  @college_rank_costs %{
    "debt_to_earnings" => :debt_median,
    "graddebt_to_earnings" => :graduated_debt_median,
    "yearly_earnings" => :yearly_cost
  }
  @college_rank_counts [100, 250, 500, 1000]

  def rank(conn, params) do
    {measure, dir} = ranking = college_ranking(params["rank"])
    count = case Integer.parse(to_string(params["count"])) do
      {count, ""} when count in @college_rank_counts -> count
      _ -> 100
    end

    ranks = Colleges.get_colleges_by_costs(@college_rank_costs[measure], :earnings_median_after10, if(dir == "top", do: :top, else: :bottom), count)

    render(conn, "rank.html",
      ranks: ranks,
      ranking: ranking,
      count: count,
      rank_counts: @college_rank_counts,
      page_title: "Best Value Colleges Ranked by ROI: Earnings vs. Debt",
      meta_description: @rank_description
    )
  end

  def show(conn, %{"name" => name, "unitid" => unitid}) do
    case Colleges.find_college_page(unitid, name) do
      {:ok, college} ->
        payoff = Collegevalue.Fields.college_payoff(college.id)

        render(conn, "show.html",
          college: college,
          majors: Colleges.get_majors_by_college(college.name),
          payoff: payoff,
          page_title: college_page_title(college, payoff),
          noindex: not Colleges.indexable?(college)
        )

      {:redirect, college} ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: college_page_path(college.unitid, college.name))

      :error ->
        raise Ecto.NoResultsError, queryable: Collegevalue.Colleges.College
    end
  end



end
