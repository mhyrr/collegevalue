alias Collegevalue.Location
alias Collegevalue.Location.Zipcode

IO.inspect("building zip code list")

zips = File.stream!("data/zips.csv")
|> CSV.decode(headers: true)
|> Enum.map(fn {:ok, record} ->

  zip = record["ZIP"]
  lat = record["LAT"]
  lon = String.trim(record["LNG"])

  case Location.create_zipcode(%{
    zipcode: zip,
    latitude: lat,
    longitude: lon
  }) do
    {:ok, _} ->
      nil
    {:error, error} ->
      IO.inspect("ERROR")
      IO.inspect(error)
  end


end)
