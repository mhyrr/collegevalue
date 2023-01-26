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

# {_, [institutions, fields], _} = OptionParser.parse(System.argv, strict: [])

# IO.inspect(institutions)
# IO.inspect(fields)

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

  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
        joined_errors = Enum.join(v, "; ")
        "#{acc}#{k}: #{joined_errors}\n"
      end)
  end


  def get_college_from_record(record, file) do

    if (record["UNITID"] == "NULL") do
      case Colleges.get_college_by_name(record["INSTNM"]) do
        nil ->
          case Colleges.create_college(%{
              opeid: record["OPEID6"],
              unitid: -1,
              name: record["INSTNM"],
              control: record["CONTROL"],
              city: "unknown city",
              state: "unknown state",
              zip: "unknown zip",
              url: "unknown url",
              accreditation: "unknown acc",
            } ) do
            {:ok, res} ->
              {:ok, res}
            {:error, err} ->
              IO.binwrite(file, "UNITID was NULL, #{record["INSTNM"]}")
              IO.binwrite(file, Helpers.changeset_error_to_string(err))
              {type, name} = Ecto.Changeset.fetch_field(err, :name)
              IO.binwrite(file, "#{type}: #{name}\n\n")
              {:error, err}
          end
        college ->
          college
        {:error, err} ->
          IO.binwrite(file, Helpers.changeset_error_to_string(err))
          {:error, err}
      end
    else
      case Colleges.get_college_by_name_and_unitid(record["INSTNM"], record["UNITID"]) do
        nil ->
          case Colleges.create_college(%{
              opeid: record["OPEID6"],
              unitid: record["UNITID"],
              name: record["INSTNM"],
              control: record["CONTROL"],
              city: "unknown city",
              state: "unknown state",
              zip: "unknown zip",
              url: "https://www.google.com/search?q=#{record["INSTNM"]}",
              accreditation: "unknown acc",
            } ) do
            {:ok, res} ->
              {:ok, res}
            {:error, err} ->
              IO.binwrite(file, "UNITID and NAME, #{record["INSTNM"]}, #{record["UNITID"]}")
              IO.binwrite(file, Helpers.changeset_error_to_string(err))
              {type, name} = Ecto.Changeset.fetch_field(err, :name)
              IO.binwrite(file, "#{type}: #{name}\n")
              {:error, err}
          end
        college ->
          college
      end
    end


  end


end

IO.inspect("Parsing cohort data..")

{:ok, file} = File.open "data/error.log", [:append, {:delayed_write, 100, 20}]

# ccount = File.stream!("data/All100_new.csv")
# ccount = File.stream!(institutions)
# ccount = File.stream!("data/Most-Recent-Cohorts-Institution.csv")
# |> CSV.decode(headers: true)
# |> Enum.map(fn {:ok, record} ->
#     # IO.inspect("record..")
#     yearly_costs = Helpers.yearly({record["COSTT4_A"], record["COSTT4_P"]})
#     netprice_1 = Helpers.net({record["NPT41_PUB"], record["NPT41_PRIV"]})
#     netprice_2 = Helpers.net({record["NPT42_PUB"], record["NPT42_PRIV"]})
#     netprice_3 = Helpers.net({record["NPT43_PUB"], record["NPT43_PRIV"]})
#     netprice_4 = Helpers.net({record["NPT44_PUB"], record["NPT44_PRIV"]})
#     netprice_5 = Helpers.net({record["NPT45_PUB"], record["NPT45_PRIV"]})
#     admissions_rate = Helpers.check_incomplete(record["ADM_RATE"])

#     ugds = Helpers.check_incomplete(record["UGDS"])
#     ugds_men = Helpers.check_incomplete(record["UGDS_MEN"])
#     ugds_women = Helpers.check_incomplete(record["UGDS_WOMEN"])

#     sat_avg = Helpers.check_incomplete(record["SAT_AVG"])
#     sat_verbal_25 = Helpers.check_incomplete(record["SATVR25"])
#     sat_verbal_mid = Helpers.check_incomplete(record["SATVRMID"])
#     sat_verbal_75 = Helpers.check_incomplete(record["SATVR75"])
#     sat_math_25 = Helpers.check_incomplete(record["SATMT25"])
#     sat_math_mid = Helpers.check_incomplete(record["SATMTMID"])
#     sat_math_75 = Helpers.check_incomplete(record["SATMT75"])
#     act_comp_25 = Helpers.check_incomplete(record["ACTCM25"])
#     act_comp_mid = Helpers.check_incomplete(record["ACTCMMID"])
#     act_comp_75 = Helpers.check_incomplete(record["ACTCM75"])


#     tuition_out = Helpers.check_incomplete(record["TUITIONFEE_OUT"])
#     tuition_in = Helpers.check_incomplete(record["TUITIONFEE_IN"])
#     percent_loans = Helpers.check_incomplete(record["FTFTPCTFLOAN"])
#     debt_median = Helpers.check_incomplete(record["DEBT_MDN"])
#     graduated_debt_median = Helpers.check_incomplete(record["GRAD_DEBT_MDN"])
#     withdrawn_debt_median = Helpers.check_incomplete(record["WDRAW_DEBT_MDN"])
#     low_income_debt_median = Helpers.check_incomplete(record["LO_INC_DEBT_MDN"])
#     medium_income_debt_median = Helpers.check_incomplete(record["MD_INC_DEBT_MDN"])
#     high_income_debt_median = Helpers.check_incomplete(record["HI_INC_DEBT_MDN"])

#     # 2 For earnings variables that are disaggregated by FAFSA family income tercile (low-income: $30,000 or less;
#     # middle-income: $30,001-$75,000; and high-income: $75,001+), family income was adjusted for inflation prior to
#     # grouping by tercile.

#     # https://collegescorecard.ed.gov/assets/InstitutionDataDocumentation.pdf
#     # "At institutions where large numbers of students withdraw before
#     # completion, a lower median debt level could simply reflect the lack of
#     # time that a typical student spends at the institution. Therefore, the
#     # Department uses the typical debt level for students who complete
#     # (GRAD_DEBT_MDN_SUPP or GRAD_DEBT_MDN10YR_SUPP for the debt
#     # level expressed in monthly payments26) on the consumer website.
#     # Additionally, this measure can be placed in context by looking at the
#     # borrowing rate of students at the institution (FTFTPCTFLOAN; see
#     # above); at institutions where few students borrow, the numbers may
#     # represent outliers."

#     fouryear_100_completion = Helpers.check_incomplete(record["C100_4"])
#     fouryear_150_completion = Helpers.check_incomplete(record["C150_4"])
#     fouryear_200_completion = Helpers.check_incomplete(record["C200_4"])

#     l4y_100_completion = Helpers.check_incomplete( record["C100_L4"])
#     l4y_150_completion = Helpers.check_incomplete(record["C150_L4"])
#     l4y_200_completion = Helpers.check_incomplete(record["C200_L4"])

#     # One of the most common reasons students cite in choosing to go to college is the expansion of
#     # employment opportunities. To that end, data on the earnings and employment prospects of former
#     # students can provide key information. To measure the labor market outcomes of individuals attending
#     # institutions of higher education, data on cohorts of federally aided undergraduate students were linked
#     # with earnings data from de-identified tax records and reported back at the aggregate, institutional level.
#     # Mean earnings data elements at the institution-level were last updated in the fall of 2018. See Appendix
#     # B for information about those metrics.
#     # There are two notable limitations that researchers should keep in mind for all of these metrics. First,
#     # research suggests that the variation across programs within an institution may be even greater than
#     # aggregate earnings across institutions. For information related to more recent earnings calculations by
#     # field of study, please see the technical documentation for field of study data files. Second, the data
#     # include only Title IV-receiving students, so figures may not be representative of institutions with a low
#     # proportion of Title IV-eligible students. Additionally, the data are restricted to students who are not
#     # enrolled (enrolled means having an in-school deferment status for at least 30 days of the measurement
#     # so students who are currently enrolled in, for example, graduate school at the time of
#     # measurement are excluded.

#     earnings_mean_after10 = Helpers.check_incomplete(record["MN_EARN_WNE_P10"])
#     earnings_mean_after9 = Helpers.check_incomplete(record["MN_EARN_WNE_P9"])
#     earnings_mean_after8 = Helpers.check_incomplete(record["MN_EARN_WNE_P8"])
#     earnings_mean_after7 = Helpers.check_incomplete(record["MN_EARN_WNE_P7"])
#     earnings_mean_after6 = Helpers.check_incomplete(record["MN_EARN_WNE_P6"])
#     earnings_median_after10 = Helpers.check_incomplete(record["MD_EARN_WNE_P10"])
#     earnings_median_after9  = Helpers.check_incomplete(record["MD_EARN_WNE_P9"])
#     earnings_median_after8 = Helpers.check_incomplete(record["MD_EARN_WNE_P8"])
#     earnings_median_after7 = Helpers.check_incomplete(record["MD_EARN_WNE_P7"])
#     earnings_median_after6 = Helpers.check_incomplete(record["MD_EARN_WNE_P6"])

#     low_family_earnings_median_after6 = Helpers.check_incomplete(record["MD_EARN_WNE_INC1_P6"])
#     medium_family_earnings_median_after6 = Helpers.check_incomplete(record["MD_EARN_WNE_INC2_P6"])
#     high_family_earnings_median_after6 = Helpers.check_incomplete(record["MD_EARN_WNE_INC3_P6"])
#     low_family_earnings_median_after8 = Helpers.check_incomplete(record["MD_EARN_WNE_INC1_P8"])
#     medium_family_earnings_median_after8 = Helpers.check_incomplete(record["MD_EARN_WNE_INC2_P8"])
#     high_family_earnings_median_after8 = Helpers.check_incomplete(record["MD_EARN_WNE_INC3_P8"])
#     low_family_earnings_median_after10 = Helpers.check_incomplete(record["MD_EARN_WNE_INC1_P10"])
#     medium_family_earnings_median_after10 = Helpers.check_incomplete(record["MD_EARN_WNE_INC2_P10"])
#     high_family_earnings_median_after10 = Helpers.check_incomplete(record["MD_EARN_WNE_INC3_P10"])

#     high_degree = Helpers.check_incomplete(record["HIGHDEG"])
#     institution_level = Helpers.check_incomplete(record["ICLEVEL"])
#     predominant_degree = Helpers.check_incomplete(record["PREDDEG"])
#     inst_degree = Helpers.check_incomplete(record["SCH_DEG"])

#     latitude = Helpers.check_incomplete(record["LATITUDE"])
#     longitude = Helpers.check_incomplete(record["LONGITUDE"])
#     control = Helpers.check_incomplete(record["CONTROL"])
#     distanceonly = Helpers.check_incomplete(record["DISTANCEONLY"])

#     net_tuition_revenue = Helpers.check_incomplete(record["TUITFTE"])
#     inst_exp = Helpers.check_incomplete(record["INEXPFTE"])
#     avg_faculty_salary = Helpers.check_incomplete(record["AVGFACSAL"]) # This is monthly salary




#     case Colleges.create_college(%{
#       opeid: record["OPEID6"],
#       unitid: record["UNITID"],
#       name: record["INSTNM"],
#       control: control,
#       city: record["CITY"],
#       state: record["STABBR"],
#       zip: record["ZIP"],
#       url: record["INSTURL"],
#       accreditation: record["ACCREDAGENCY"],
#       institution_level: institution_level,
#       high_degree: high_degree,
#       predominant_degree: predominant_degree,
#       inst_degree: inst_degree,
#       admissions_rate: admissions_rate,

#       ugds: ugds,
#       ugds_men: ugds_men,
#       ugds_women: ugds_women,

#       sat_avg: sat_avg,
#       sat_verbal_25: sat_verbal_25,
#       sat_verbal_mid: sat_verbal_mid,
#       sat_verbal_75: sat_verbal_75,
#       sat_math_25: sat_math_25,
#       sat_math_mid: sat_math_mid,
#       sat_math_75: sat_math_75,
#       act_comp_25: act_comp_25,
#       act_comp_mid: act_comp_mid,
#       act_comp_75: act_comp_75,


#       yearly_cost: yearly_costs,
#       tuition_out: tuition_out,
#       tuition_in: tuition_in,
#       debt_median: debt_median,
#       graduated_debt_median: graduated_debt_median,
#       withdrawn_debt_median: withdrawn_debt_median,

#       low_income_debt_median: low_income_debt_median,
#       medium_income_debt_median: medium_income_debt_median,
#       high_income_debt_median: high_income_debt_median,

#       netprice_1: netprice_1,
#       netprice_2: netprice_2,
#       netprice_3: netprice_3,
#       netprice_4: netprice_4,
#       netprice_5: netprice_5,
#       fouryear_100_completion: fouryear_100_completion,
#       fouryear_150_completion: fouryear_150_completion,
#       fouryear_200_completion: fouryear_200_completion,
#       l4y_100_completion: l4y_100_completion,
#       l4y_150_completion: l4y_150_completion,
#       l4y_200_completion: l4y_200_completion,
#       earnings_mean_after10: earnings_mean_after10,
#       earnings_mean_after9: earnings_mean_after9,
#       earnings_mean_after8: earnings_mean_after8,
#       earnings_mean_after7: earnings_mean_after7,
#       earnings_mean_after6: earnings_mean_after6,
#       earnings_median_after10: earnings_median_after10,
#       earnings_median_after9: earnings_median_after9,
#       earnings_median_after8: earnings_median_after8,
#       earnings_median_after7: earnings_median_after7,
#       earnings_median_after6: earnings_median_after6,

#       low_family_earnings_median_after6: low_family_earnings_median_after6,
#       medium_family_earnings_median_after6: medium_family_earnings_median_after6,
#       high_family_earnings_median_after6: high_family_earnings_median_after6,
#       low_family_earnings_median_after8: low_family_earnings_median_after8,
#       medium_family_earnings_median_after8: medium_family_earnings_median_after8,
#       high_family_earnings_median_after8: high_family_earnings_median_after8,
#       low_family_earnings_median_after10: low_family_earnings_median_after10,
#       medium_family_earnings_median_after10: medium_family_earnings_median_after10,
#       high_family_earnings_median_after10: high_family_earnings_median_after10,

#       latitude: latitude,
#       longitude: longitude,
#       distanceonly: distanceonly,
#       net_tuition_revenue: net_tuition_revenue,
#       institutional_expense_per: inst_exp,
#       avg_faculty_salary: avg_faculty_salary


#     }) do
#       {:ok, _} ->
#         nil
#       {:error, error} ->
#         IO.inspect("ERROR")
#         IO.inspect(error)
#         IO.binwrite(file, "Tried creating a college from institution data")
#         IO.binwrite(file, Helpers.changeset_error_to_string(error))
#         {type, name} = Ecto.Changeset.fetch_field(error, :name)
#         IO.binwrite(file, "#{type}: #{name}\n\n")
#     end


#     # IO.inspect(created_coll)

#   end)


# Map out any other colleges in field data

IO.inspect("Parsing field data..")

# adtl = File.stream!("data/Field100_new.csv")
# adtl = File.stream!(fields)
adtl = File.stream!("data/Most-Recent-Cohorts-Field-of-Study.csv")
|> CSV.decode(headers: true)
|> Enum.map(fn {:ok, record} ->

  college = Helpers.get_college_from_record(record, file)

  # IO.inspect(college)

  # IO.inspect(Collegevalue.Colleges.get_college_by_opeid(record["OPEID6"]))

  count = if (record["IPEDSCOUNT1"] == "NULL"), do: -1, else: record["IPEDSCOUNT1"]
  pp_debt_mean =  if (record["DEBT_ALL_PP_ANY_MEAN"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_PP_ANY_MEAN"]
  pp_debt_median = if (record["DEBT_ALL_PP_ANY_MDN"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_PP_ANY_MDN"]
  pp_debt_payment = if (record["DEBT_ALL_PP_ANY_MDN10YRPAY"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_PP_ANY_MDN10YRPAY"]
  pp_debt_count = if (record["DEBT_ALL_PP_ANY_N"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_PP_ANY_N"]

  stgp_debt_mean =  if (record["DEBT_ALL_STGP_ANY_MEAN"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_STGP_ANY_MEAN"]
  stgp_debt_median = if (record["DEBT_ALL_STGP_ANY_MDN"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_STGP_ANY_MDN"]
  stgp_debt_payment = if (record["DEBT_ALL_STGP_ANY_MDN10YRPAY"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_STGP_ANY_MDN10YRPAY"]
  stgp_debt_count = if (record["DEBT_ALL_STGP_ANY_N"] == "PrivacySuppressed"), do: -1, else: record["DEBT_ALL_STGP_ANY_N"]

  earnings_1yr = if (record["EARN_MDN_HI_1YR"] == "PrivacySuppressed" || record["EARN_MDN_HI_1YR"] == "NULL"), do: -1, else: record["EARN_MDN_HI_1YR"]
  earnings_1yr_count = if (record["EARN_COUNT_WNE_HI_1YR"] == "PrivacySuppressed" || record["EARN_COUNT_WNE_HI_1YR"] == "NULL"), do: -1, else: record["EARN_COUNT_WNE_HI_1YR"]
  earnings_2yr = if (record["EARN_MDN_HI_2YR"] == "PrivacySuppressed" || record["EARN_MDN_HI_2YR"] == "NULL"), do: -1, else: record["EARN_MDN_HI_2YR"]
  earnings_2yr_count = if (record["EARN_COUNT_WNE_HI_2YR"] == "PrivacySuppressed" || record["EARN_COUNT_WNE_HI_2YR"] == "NULL"), do: -1, else: record["EARN_COUNT_WNE_HI_2YR"]

  debt_counts = [
    (if (pp_debt_count == -1), do: 0, else: String.to_integer(pp_debt_count)),
    (if (stgp_debt_count == -1), do: 0, else: String.to_integer(stgp_debt_count)),
  ]
  titleiv_count = Enum.sum(debt_counts)

  id = case college do
    nil ->
      -1
    {:error, _res} ->
      case Helpers.get_college_from_record(record, file) do
        nil ->
          -1
        {:error, _} ->
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
    count: count,
    pp_debt_count: pp_debt_count,
    pp_debt_mean: pp_debt_mean,
    pp_debt_median: pp_debt_median,
    pp_debt_payment: pp_debt_payment,
    stgp_debt_count: stgp_debt_count,
    stgp_debt_mean: stgp_debt_mean,
    stgp_debt_median: stgp_debt_median,
    stgp_debt_payment: stgp_debt_payment,
    earnings_1yr: earnings_1yr,
    earnings_1yr_count: earnings_1yr_count,
    earnings_2yr: earnings_2yr,
    earnings_2yr_count: earnings_2yr_count,
    titleiv_count: titleiv_count,
    name: String.trim_trailing(record["CIPDESC"], "."),
    college_id: id
  }) do
    {:ok, res} ->
      {:ok, res}
    {:error, err} ->
      {:error, err}
      IO.binwrite(file, "Create discipline")
      IO.binwrite(file, Helpers.changeset_error_to_string(err))
      {type, name} = Ecto.Changeset.fetch_field(err, :name)
      IO.binwrite(file, "#{type}: #{name}\n\n")
      IO.inspect("ERROR")
      IO.inspect(err)
  end

  # IO.inspect(disc)

  [college, disc]
end)
# |> Enum.reduce(%{cnt: 0, err: 0, existed: 0, disc: 0, derr: 0}, fn res, acc ->

#   case List.first(res) do
#     {:ok, _c} ->
#       %{acc | :cnt => acc[:cnt] + 1}
#     {:error, _err} ->
#       %{acc | :err => acc[:err] + 1}
#     college ->
#       %{acc | :cnt => acc[:cnt] + 1}
#     nil ->
#       %{acc | :existed => acc[:existed] + 1}
#   end

#   case List.last(res) do
#     {:ok, _d} ->
#       %{acc | :disc => acc[:disc] + 1}
#     {:error, _err} ->
#       %{acc | :derr => acc[:derr] + 1}
#   end

# end)

# IO.puts "College count: #{ccount}, added #{adtl[:cnt]}, failed #{adtl[:err]}, existed #{adtl[:existed]}"
# IO.puts "Discipline count: #{adtl[:disc]}, Errs: #{adtl[:derr]}"
