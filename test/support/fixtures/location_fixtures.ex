defmodule Collegevalue.LocationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Collegevalue.Location` context.
  """

  @doc """
  Generate a zipcode.
  """
  def zipcode_fixture(attrs \\ %{}) do
    {:ok, zipcode} =
      attrs
      |> Enum.into(%{
        latitude: 120.5,
        longitude: 120.5,
        zipcode: "some zipcode"
      })
      |> Collegevalue.Location.create_zipcode()

    zipcode
  end
end
