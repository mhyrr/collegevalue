defmodule Collegevalue.CollegesTest do
  use Collegevalue.DataCase

  alias Collegevalue.Colleges

  describe "colleges" do
    alias Collegevalue.Colleges.College

    @valid_attrs %{accreditation: "some accreditation", city: "some city", control: "some control", name: "some name", opeid: 42, state: "some state", unitid: 42, url: "some url", zip: "some zip"}
    @update_attrs %{accreditation: "some updated accreditation", city: "some updated city", control: "some updated control", name: "some updated name", opeid: 43, state: "some updated state", unitid: 43, url: "some updated url", zip: "some updated zip"}
    @invalid_attrs %{accreditation: nil, city: nil, control: nil, name: nil, opeid: nil, state: nil, unitid: nil, url: nil, zip: nil}

    def college_fixture(attrs \\ %{}) do
      {:ok, college} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Colleges.create_college()

      college
    end

    test "list_colleges/0 returns all colleges" do
      college = college_fixture()
      assert Colleges.list_colleges() == [college]
    end

    test "get_college!/1 returns the college with given id" do
      college = college_fixture()
      assert Colleges.get_college!(college.id) == college
    end

    test "create_college/1 with valid data creates a college" do
      assert {:ok, %College{} = college} = Colleges.create_college(@valid_attrs)
      assert college.accreditation == "some accreditation"
      assert college.city == "some city"
      assert college.control == "some control"
      assert college.name == "some name"
      assert college.opeid == 42
      assert college.state == "some state"
      assert college.unitid == 42
      assert college.url == "some url"
      assert college.zip == "some zip"
    end

    test "create_college/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Colleges.create_college(@invalid_attrs)
    end

    test "update_college/2 with valid data updates the college" do
      college = college_fixture()
      assert {:ok, %College{} = college} = Colleges.update_college(college, @update_attrs)
      assert college.accreditation == "some updated accreditation"
      assert college.city == "some updated city"
      assert college.control == "some updated control"
      assert college.name == "some updated name"
      assert college.opeid == 43
      assert college.state == "some updated state"
      assert college.unitid == 43
      assert college.url == "some updated url"
      assert college.zip == "some updated zip"
    end

    test "update_college/2 with invalid data returns error changeset" do
      college = college_fixture()
      assert {:error, %Ecto.Changeset{}} = Colleges.update_college(college, @invalid_attrs)
      assert college == Colleges.get_college!(college.id)
    end

    test "delete_college/1 deletes the college" do
      college = college_fixture()
      assert {:ok, %College{}} = Colleges.delete_college(college)
      assert_raise Ecto.NoResultsError, fn -> Colleges.get_college!(college.id) end
    end

    test "change_college/1 returns a college changeset" do
      college = college_fixture()
      assert %Ecto.Changeset{} = Colleges.change_college(college)
    end
  end

  describe "disciplines" do
    alias Collegevalue.Colleges.Discipline

    @valid_attrs %{cipcode: 42, credential_desc: "some credential_desc", credential_level: 42, debt_count: 42, debt_mean: 42, debt_median: 42, debt_payment: 42, earnings: 42, earnings_count: 42, name: "some name", titleiv_count: 42}
    @update_attrs %{cipcode: 43, credential_desc: "some updated credential_desc", credential_level: 43, debt_count: 43, debt_mean: 43, debt_median: 43, debt_payment: 43, earnings: 43, earnings_count: 43, name: "some updated name", titleiv_count: 43}
    @invalid_attrs %{cipcode: nil, credential_desc: nil, credential_level: nil, debt_count: nil, debt_mean: nil, debt_median: nil, debt_payment: nil, earnings: nil, earnings_count: nil, name: nil, titleiv_count: nil}

    def discipline_fixture(attrs \\ %{}) do
      {:ok, discipline} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Colleges.create_discipline()

      discipline
    end

    test "list_disciplines/0 returns all disciplines" do
      discipline = discipline_fixture()
      assert Colleges.list_disciplines() == [discipline]
    end

    test "get_discipline!/1 returns the discipline with given id" do
      discipline = discipline_fixture()
      assert Colleges.get_discipline!(discipline.id) == discipline
    end

    test "create_discipline/1 with valid data creates a discipline" do
      assert {:ok, %Discipline{} = discipline} = Colleges.create_discipline(@valid_attrs)
      assert discipline.cipcode == 42
      assert discipline.credential_desc == "some credential_desc"
      assert discipline.credential_level == 42
      assert discipline.debt_count == 42
      assert discipline.debt_mean == 42
      assert discipline.debt_median == 42
      assert discipline.debt_payment == 42
      assert discipline.earnings == 42
      assert discipline.earnings_count == 42
      assert discipline.name == "some name"
      assert discipline.titleiv_count == 42
    end

    test "create_discipline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Colleges.create_discipline(@invalid_attrs)
    end

    test "update_discipline/2 with valid data updates the discipline" do
      discipline = discipline_fixture()
      assert {:ok, %Discipline{} = discipline} = Colleges.update_discipline(discipline, @update_attrs)
      assert discipline.cipcode == 43
      assert discipline.credential_desc == "some updated credential_desc"
      assert discipline.credential_level == 43
      assert discipline.debt_count == 43
      assert discipline.debt_mean == 43
      assert discipline.debt_median == 43
      assert discipline.debt_payment == 43
      assert discipline.earnings == 43
      assert discipline.earnings_count == 43
      assert discipline.name == "some updated name"
      assert discipline.titleiv_count == 43
    end

    test "update_discipline/2 with invalid data returns error changeset" do
      discipline = discipline_fixture()
      assert {:error, %Ecto.Changeset{}} = Colleges.update_discipline(discipline, @invalid_attrs)
      assert discipline == Colleges.get_discipline!(discipline.id)
    end

    test "delete_discipline/1 deletes the discipline" do
      discipline = discipline_fixture()
      assert {:ok, %Discipline{}} = Colleges.delete_discipline(discipline)
      assert_raise Ecto.NoResultsError, fn -> Colleges.get_discipline!(discipline.id) end
    end

    test "change_discipline/1 returns a discipline changeset" do
      discipline = discipline_fixture()
      assert %Ecto.Changeset{} = Colleges.change_discipline(discipline)
    end
  end
end
