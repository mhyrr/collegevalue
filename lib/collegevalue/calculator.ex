defmodule Collegevalue.Calculator do
  import Ecto.Query, warn: false
  alias Collegevalue.Repo
  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Fields.Field

  defmodule Projection do
    defstruct [
      :college_name,
      :college_id,
      :unit_id,
      :url,
      :net_price,
      :total_cost,
      :major_debt,
      :college_debt,
      :debt_used,
      :debt_source,
      :major_earnings_1yr,
      :major_earnings_2yr,
      :college_earnings_10yr,
      :roi_debt,
      :roi_cost,
      :debt_to_earnings_ratio,
      :admissions_rate,
      :sat_avg,
      :completion_rate
    ]
  end

  def list_popular_majors do
    query = from f in Field,
      where: f.count > 50,
      order_by: [asc: :name],
      select: f.name

    Repo.all(query)
  end

  def calculate(params) do
    %{
      income_band: income_band,
      major: major,
      zip: zip,
      distance: distance
    } = params

    sat = Map.get(params, :sat)
    net_price_field = income_band_to_field(income_band)

    # Find nearby colleges first (subquery avoids GROUP BY conflict with disciplines)
    nearby = from(c in College)
    |> Colleges.with_location(zip, distance)

    nearby = if sat && sat != "" do
      score = if is_binary(sat), do: String.to_integer(sat), else: sat
      nearby
      |> where([c], c.sat_avg < ^(score + 100))
      |> where([c], c.sat_avg > ^(score - 200))
      |> where([c], c.sat_avg != -1)
    else
      nearby
    end

    nearby_ids = nearby |> select([c], c.id) |> Repo.all()

    from(d in Discipline,
      join: c in College,
      on: d.college_id == c.id,
      where: d.name == ^major,
      where: d.credential_level == 3,
      where: c.id in ^nearby_ids,
      select: %{
        college_name: c.name,
        college_id: c.id,
        unit_id: c.unitid,
        url: c.url,
        net_price: field(c, ^net_price_field),
        major_debt: d.pp_debt_median,
        major_earnings_1yr: d.earnings_1yr,
        major_earnings_2yr: d.earnings_2yr,
        college_earnings_10yr: c.earnings_median_after10,
        college_debt: c.debt_median,
        admissions_rate: c.admissions_rate,
        sat_avg: c.sat_avg,
        completion_rate: c.fouryear_200_completion
      }
    )
    |> Repo.all()
    |> Enum.map(&to_projection/1)
    |> Enum.filter(fn p -> p.college_earnings_10yr && p.college_earnings_10yr > 0 end)
    |> Enum.sort_by(fn p -> p.roi_debt || p.roi_cost || 0 end, :desc)
  end

  defp to_projection(row) do
    major_debt = safe_val(row.major_debt)
    college_debt = safe_val(row.college_debt)
    net_price = safe_val(row.net_price)
    earnings_10yr = safe_val(row.college_earnings_10yr)

    # Best available debt: major-specific > college-level
    {debt, debt_source} = cond do
      major_debt -> {major_debt, :major}
      college_debt -> {college_debt, :college}
      true -> {nil, nil}
    end

    # Total 4-year cost of attendance
    total_cost = if net_price, do: net_price * 4, else: nil

    # ROI (Debt): earnings vs what you borrowed
    roi_debt = if earnings_10yr && debt do
      earnings_10yr - debt
    else
      nil
    end

    # ROI (Cost): earnings vs total investment (net price * 4 years)
    roi_cost = if earnings_10yr && total_cost do
      earnings_10yr - total_cost
    else
      nil
    end

    earnings_1yr = safe_val(row.major_earnings_1yr)
    ratio = if debt && debt > 0 && earnings_1yr && earnings_1yr > 0 do
      Float.round(debt / earnings_1yr, 2)
    else
      nil
    end

    %Projection{
      college_name: row.college_name,
      college_id: row.college_id,
      unit_id: row.unit_id,
      url: row.url,
      net_price: net_price,
      total_cost: total_cost,
      major_debt: major_debt,
      college_debt: college_debt,
      debt_used: debt,
      debt_source: debt_source,
      major_earnings_1yr: earnings_1yr,
      major_earnings_2yr: safe_val(row.major_earnings_2yr),
      college_earnings_10yr: earnings_10yr,
      roi_debt: roi_debt,
      roi_cost: roi_cost,
      debt_to_earnings_ratio: ratio,
      admissions_rate: row.admissions_rate,
      sat_avg: row.sat_avg,
      completion_rate: row.completion_rate
    }
  end

  defp safe_val(nil), do: nil
  defp safe_val(v) when v <= 0, do: nil
  defp safe_val(v), do: v

  defp income_band_to_field(1), do: :netprice_1
  defp income_band_to_field(2), do: :netprice_2
  defp income_band_to_field(3), do: :netprice_3
  defp income_band_to_field(4), do: :netprice_4
  defp income_band_to_field(5), do: :netprice_5
  defp income_band_to_field(_), do: :netprice_3
end
