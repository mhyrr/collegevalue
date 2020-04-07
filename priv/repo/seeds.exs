# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Collegevalue.Repo.insert!(%Collegevalue.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Collegevalue.Colleges

# Build primary colleges
# Full data dictionary: https://collegescorecard.ed.gov/assets/FullDataDocumentation.pdf
# Fields data dictionary: https://collegescorecard.ed.gov/assets/FieldOfStudyDataDocumentation.pdf

defmodule Helpers do

  def check_incomplete(value) do
    case value do
      "NULL" ->
        -1
      "" ->
        -1
      "PrivacySuppressed" ->
        -2
      _ ->
        value
    end
  end

  def yearly(costs) do

    case costs do
      {"NULL", "NULL"} ->
        -1
      {"NULL", cost} ->
        cost
      {cost, "NULL"} ->
        cost
      {"", ""} ->
        -1
      {"", cost} ->
        cost
      {cost, ""} ->
        cost
      {a, _} ->
        a
    end

  end


  def net(prices) do
    case prices do
      {"NULL", "NULL"} ->
        -1
      {"NULL", price} ->
        price
      {price, "NULL"} ->
        price
      {"", ""} ->
        -1
      {"", price} ->
        price
      {price, ""} ->
        price
      {a, _} ->
        a
    end
  end

end

IO.inspect("Parsing cohort data..")

# ccount = File.stream!("data/All100.csv")
ccount = File.stream!("data/Most-Recent-Cohorts-All-Data-Elements.csv")
|> CSV.decode(headers: true)
|> Stream.map(fn {:ok, record} ->
    yearly_costs = Helpers.yearly({record["COSTT4_A"], record["COSTT4_P"]})
    netprice_1 = Helpers.net({record["NPT41_PUB"], record["NPT41_PRIV"]})
    netprice_2 = Helpers.net({record["NPT42_PUB"], record["NPT42_PRIV"]})
    netprice_3 = Helpers.net({record["NPT43_PUB"], record["NPT43_PRIV"]})
    netprice_4 = Helpers.net({record["NPT44_PUB"], record["NPT44_PRIV"]})
    netprice_5 = Helpers.net({record["NPT45_PUB"], record["NPT45_PRIV"]})
    admissions_rate = Helpers.check_incomplete(record["ADM_RATE"])
    sat_avg = Helpers.check_incomplete(record["SAT_AVG"])
    tuition_out = Helpers.check_incomplete(record["TUITIONFEE_OUT"])
    tuition_in = Helpers.check_incomplete(record["TUITIONFEE_IN"])
    debt_median = Helpers.check_incomplete(record["DEBT_MDN"])
    graduated_debt_median = Helpers.check_incomplete(record["GRAD_DEBT_MDN"])
    withdrawn_debt_median = Helpers.check_incomplete(record["WDRAW_DEBT_MDN"])
    fouryear_100_completion = Helpers.check_incomplete(record["C100_4"])
    fouryear_150_completion = Helpers.check_incomplete(record["C150_4"])
    l4y_100_completion = Helpers.check_incomplete( record["C100_L4"])
    l4y_150_completion = Helpers.check_incomplete(record["c150_L4"])
    earnings_mean_after10 = Helpers.check_incomplete(record["MN_EARN_WNE_P10"])
    earnings_mean_after9 = Helpers.check_incomplete(record["MN_EARN_WNE_P9"])
    earnings_mean_after8 = Helpers.check_incomplete(record["MN_EARN_WNE_P8"])
    earnings_mean_after7 = Helpers.check_incomplete(record["MN_EARN_WNE_P7"])
    earnings_mean_after6 = Helpers.check_incomplete(record["MN_EARN_WNE_P6"])
    earnings_median_after10 = Helpers.check_incomplete(record["MD_EARN_WNE_P10"])
    earnings_median_after9  = Helpers.check_incomplete(record["MD_EARN_WNE_P9"])
    earnings_median_after8 = Helpers.check_incomplete(record["MD_EARN_WNE_P8"])
    earnings_median_after7 = Helpers.check_incomplete(record["MD_EARN_WNE_P7"])
    earnings_median_after6 = Helpers.check_incomplete(record["MD_EARN_WNE_P6"])

    high_degree = Helpers.check_incomplete(record["HIGHDEG"])
    institution_level = Helpers.check_incomplete(record["ICLEVEL"])
    predominant_degree = Helpers.check_incomplete(record["PREDDEG"])
    inst_degree = Helpers.check_incomplete(record["SCH_DEG"])

    case Colleges.create_college(%{
      opeid: record["OPEID6"],
      unitid: record["\uFEFFUNITID"],
      name: record["INSTNM"],
      control: "unknown",
      city: record["CITY"],
      state: record["STABBR"],
      zip: record["ZIP"],
      url: record["INSTURL"],
      accreditation: record["ACCREDAGENCY"],
      institution_level: institution_level,
      high_degree: high_degree,
      predominant_degree: predominant_degree,
      inst_degree: inst_degree,

      admissions_rate: admissions_rate,
      sat_avg: sat_avg,
      yearly_cost: yearly_costs,
      tuition_out: tuition_out,
      tuition_in: tuition_in,
      debt_median: debt_median,
      graduated_debt_median: graduated_debt_median,
      withdrawn_debt_median: withdrawn_debt_median,
      netprice_1: netprice_1,
      netprice_2: netprice_2,
      netprice_3: netprice_3,
      netprice_4: netprice_4,
      netprice_5: netprice_5,
      fouryear_100_completion: fouryear_100_completion,
      fouryear_150_completion: fouryear_150_completion,
      l4y_100_completion: l4y_100_completion,
      l4y_150_completion: l4y_150_completion,
      earnings_mean_after10: earnings_mean_after10,
      earnings_mean_after9: earnings_mean_after9,
      earnings_mean_after8: earnings_mean_after8,
      earnings_mean_after7: earnings_mean_after7,
      earnings_mean_after6: earnings_mean_after6,
      earnings_median_after10: earnings_median_after10,
      earnings_median_after9: earnings_median_after9,
      earnings_median_after8: earnings_median_after8,
      earnings_median_after7: earnings_median_after7,
      earnings_median_after6: earnings_median_after6

    }) do
      {:ok, _} ->
        nil
      {:error, error} ->
        IO.inspect("ERROR")
        IO.inspect(error)
    end
  end)
|> Enum.reduce(0, fn _x, acc -> 1+acc end)

# Map out any other colleges in field data

IO.inspect("Parsing field data..")

# adtl = File.stream!("data/Field100.csv")
adtl = File.stream!("data/Most-Recent-Field-Data-Elements.csv")
|> CSV.decode(headers: true)
|> Stream.map(fn {:ok, record} ->

  college = case Colleges.get_college_by_name(record["INSTNM"]) do
    nil ->
      case Colleges.create_college(%{
          opeid: record["OPEID6"],
          unitid: record["\uFEFFUNITID"],
          name: record["INSTNM"],
          control: record["CONTROL"],
          city: "city",
          state: "state",
          zip: "zip",
          url: "url",
          accreditation: "acc",
        } ) do
        {:ok, res} ->
          {:ok, res}
        {:error, err} ->
          {:error, err}
      end
    college ->
      college
  end


#   IO.inspect(Collegevalue.Colleges.get_college_by_opeid(record["OPEID6"]))

  count = if (record["COUNT"] == "PrivacySuppressed"), do: -1, else: record["COUNT"]
  debt_mean =  if (record["DEBTMEAN"] == "PrivacySuppressed"), do: -1, else: record["DEBTMEAN"]
  debt_median = if (record["DEBTMEDIAN"] == "PrivacySuppressed"), do: -1, else: record["DEBTMEDIAN"]
  debt_payment = if (record["DEBTPAYMENT10YR"] == "PrivacySuppressed"), do: -1, else: record["DEBTPAYMENT10YR"]
  earnings = if (record["MD_EARN_WNE"] == "PrivacySuppressed"), do: -1, else: record["MD_EARN_WNE"]
  earnings_count = if (record["EARNINGSCOUNT"] == "PrivacySuppressed"), do: -1, else: record["EARNINGSCOUNT"]
  titleiv_count = if (record["TITLEIVCOUNT"] == "PrivacySuppressed"), do: -1, else: record["TITLEIVCOUNT"]


  id = case college do
    nil ->
      -1
    {:error, _res} ->
      case Collegevalue.Colleges.get_college_by_name(record["INSTNM"]) do
        nil ->
          -1
        c ->
          c.id
      end
    {:ok, res} ->
      res.id
    college ->
      college.id
  end

  disc = case Collegevalue.Colleges.create_discipline(%{
    cipcode: record["CIPCODE"],
    credential_desc: String.trim_trailing(record["CIPDESC"], "."),
    credential_level: record["CREDLEV"],
    debt_count: count,
    debt_mean: debt_mean,
    debt_median: debt_median,
    debt_payment: debt_payment,
    earnings: earnings,
    earnings_count: earnings_count,
    titleiv_count: titleiv_count,
    name: String.trim_trailing(record["CIPDESC"], "."),
    college_id: id
  }) do
    {:ok, res} ->
      {:ok, res}
    {:error, err} ->
      {:error, err}
  end

  [college, disc]
end)
|> Enum.reduce(%{cnt: 0, err: 0, existed: 0, disc: 0, derr: 0}, fn res, acc ->

  case List.first(res) do
    {:ok, _c} ->
      %{acc | :cnt => acc[:cnt] + 1}
    {:error, _err} ->
      %{acc | :err => acc[:err] + 1}
    college ->
      %{acc | :cnt => acc[:cnt] + 1}
    nil ->
      %{acc | :existed => acc[:existed] + 1}
  end

  case List.last(res) do
    {:ok, _d} ->
      %{acc | :disc => acc[:disc] + 1}
    {:error, _err} ->
      %{acc | :derr => acc[:derr] + 1}
  end

end)

IO.puts "College count: #{ccount}, added #{adtl[:cnt]}, failed #{adtl[:err]}, existed #{adtl[:existed]}"
IO.puts "Discipline count: #{adtl[:disc]}, Errs: #{adtl[:derr]}"
