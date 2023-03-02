defmodule Collegevalue.LocationTest do
  use Collegevalue.DataCase

  alias Collegevalue.Location

  describe "zips" do
    alias Collegevalue.Location.Zipcode

    import Collegevalue.LocationFixtures

    @invalid_attrs %{latitude: nil, longitude: nil, zipcode: nil}

    test "list_zips/0 returns all zips" do
      zipcode = zipcode_fixture()
      assert Location.list_zips() == [zipcode]
    end

    test "get_zipcode!/1 returns the zipcode with given id" do
      zipcode = zipcode_fixture()
      assert Location.get_zipcode!(zipcode.id) == zipcode
    end

    test "create_zipcode/1 with valid data creates a zipcode" do
      valid_attrs = %{latitude: 120.5, longitude: 120.5, zipcode: "some zipcode"}

      assert {:ok, %Zipcode{} = zipcode} = Location.create_zipcode(valid_attrs)
      assert zipcode.latitude == 120.5
      assert zipcode.longitude == 120.5
      assert zipcode.zipcode == "some zipcode"
    end

    test "create_zipcode/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Location.create_zipcode(@invalid_attrs)
    end

    test "update_zipcode/2 with valid data updates the zipcode" do
      zipcode = zipcode_fixture()
      update_attrs = %{latitude: 456.7, longitude: 456.7, zipcode: "some updated zipcode"}

      assert {:ok, %Zipcode{} = zipcode} = Location.update_zipcode(zipcode, update_attrs)
      assert zipcode.latitude == 456.7
      assert zipcode.longitude == 456.7
      assert zipcode.zipcode == "some updated zipcode"
    end

    test "update_zipcode/2 with invalid data returns error changeset" do
      zipcode = zipcode_fixture()
      assert {:error, %Ecto.Changeset{}} = Location.update_zipcode(zipcode, @invalid_attrs)
      assert zipcode == Location.get_zipcode!(zipcode.id)
    end

    test "delete_zipcode/1 deletes the zipcode" do
      zipcode = zipcode_fixture()
      assert {:ok, %Zipcode{}} = Location.delete_zipcode(zipcode)
      assert_raise Ecto.NoResultsError, fn -> Location.get_zipcode!(zipcode.id) end
    end

    test "change_zipcode/1 returns a zipcode changeset" do
      zipcode = zipcode_fixture()
      assert %Ecto.Changeset{} = Location.change_zipcode(zipcode)
    end
  end
end
