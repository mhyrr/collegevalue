defmodule Collegevalue.RankingsTest do
  use Collegevalue.DataCase

  alias Collegevalue.Rankings

  describe "ranks" do
    alias Collegevalue.Rankings.Rank

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def rank_fixture(attrs \\ %{}) do
      {:ok, rank} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rankings.create_rank()

      rank
    end

    test "list_ranks/0 returns all ranks" do
      rank = rank_fixture()
      assert Rankings.list_ranks() == [rank]
    end

    test "get_rank!/1 returns the rank with given id" do
      rank = rank_fixture()
      assert Rankings.get_rank!(rank.id) == rank
    end

    test "create_rank/1 with valid data creates a rank" do
      assert {:ok, %Rank{} = rank} = Rankings.create_rank(@valid_attrs)
    end

    test "create_rank/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rankings.create_rank(@invalid_attrs)
    end

    test "update_rank/2 with valid data updates the rank" do
      rank = rank_fixture()
      assert {:ok, %Rank{} = rank} = Rankings.update_rank(rank, @update_attrs)
    end

    test "update_rank/2 with invalid data returns error changeset" do
      rank = rank_fixture()
      assert {:error, %Ecto.Changeset{}} = Rankings.update_rank(rank, @invalid_attrs)
      assert rank == Rankings.get_rank!(rank.id)
    end

    test "delete_rank/1 deletes the rank" do
      rank = rank_fixture()
      assert {:ok, %Rank{}} = Rankings.delete_rank(rank)
      assert_raise Ecto.NoResultsError, fn -> Rankings.get_rank!(rank.id) end
    end

    test "change_rank/1 returns a rank changeset" do
      rank = rank_fixture()
      assert %Ecto.Changeset{} = Rankings.change_rank(rank)
    end
  end
end
