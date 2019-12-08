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
alias Collegevalue.Colleges.College

# Build primary colleges

ccount = 0
dcount = 0
derr = 0

File.stream!("data/Most-Recent-Cohorts-All-Data-Elements.csv")
|> CSV.decode(headers: true)
|> Enum.map(fn {:ok, record} ->
  Colleges.create_college(%{
    opeid: record["OPEID6"],
    unitid: record["\uFEFFUNITID"],
    name: record["INSTNM"],
    control: "unknown",
    city: record["CITY"],
    state: record["STABBR"],
    zip: record["ZIP"],
    url: record["INSTURL"],
    accreditation: record["ACCREDAGENCY"]
  })
  ccount = ccount + 1
end)

# Map out any other colleges in field data

File.stream!("data/Most-Recent-Field-Data-Elements.csv")
|> CSV.decode(headers: true)
|> Enum.map(fn {:ok, record} ->

  case Colleges.get_college_by_opeid(record["OPEID6"]) do
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
        {:ok, _res} ->
          ccount = ccount + 1
        {:error, err} ->
          IO.inspect(err)
      end
    _college ->
      nil
  end

  IO.inspect(record)
  IO.inspect(Collegevalue.Colleges.get_college_by_opeid(record["OPEID6"]))

  count = if (record["COUNT"] == "PrivacySuppressed"), do: -1, else: record["COUNT"]
  debt_mean =  if (record["DEBTMEAN"] == "PrivacySuppressed"), do: -1, else: record["DEBTMEAN"]
  debt_median = if (record["DEBTMEDIAN"] == "PrivacySuppressed"), do: -1, else: record["DEBTMEDIAN"]
  debt_payment = if (record["DEBTPAYMENT10YR"] == "PrivacySuppressed"), do: -1, else: record["DEBTPAYMENT10YR"]
  earnings = if (record["MD_EARN_WNE"] == "PrivacySuppressed"), do: -1, else: record["MD_EARN_WNE"]
  earnings_count = if (record["EARNINGSCOUNT"] == "PrivacySuppressed"), do: -1, else: record["EARNINGSCOUNT"]
  titleiv_count = if (record["TITLEIVCOUNT"] == "PrivacySuppressed"), do: -1, else: record["TITLEIVCOUNT"]

  case Collegevalue.Colleges.create_discipline(%{
    cipcode: record["CIPCODE"],
    credential_desc: record["CIPDESC"],
    credential_level: record["CREDLEV"],
    debt_count: count,
    debt_mean: debt_mean,
    debt_median: debt_median,
    debt_payment: debt_payment,
    earnings: earnings,
    earnings_count: earnings_count,
    titleiv_count: titleiv_count,
    name: record["CIPDESC"],
    college_id: Collegevalue.Colleges.get_college_by_opeid(String.trim_leading(record["OPEID6"], "0")).id
  }) do
    {:ok, _res} ->
      dcount = dcount + 1
    {:error, err} ->
      IO.inspect(err)
      derr = derr + 1
  end
end)

IO.puts( "College count: " <> ccount)
IO.puts "Discipline count: " <> dcount <> ", Errs: " <> derr
