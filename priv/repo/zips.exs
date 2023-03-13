alias Collegevalue.Location
alias Collegevalue.Location.Zipcode

IO.inspect("building zip code list")

zips = File.stream!("data/US.txt")
|> CSV.decode(separator: ?\t, headers: false, field_transform: &String.trim/1)
|> Enum.map(fn {:ok, record} ->

  zip = Enum.at(record, 1)
  lat = Enum.at(record, 9)
  lon = String.trim(Enum.at(record, 10))

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
