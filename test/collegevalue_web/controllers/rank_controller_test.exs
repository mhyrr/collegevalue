defmodule CollegevalueWeb.RankControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Rankings

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:rank) do
    {:ok, rank} = Rankings.create_rank(@create_attrs)
    rank
  end

  describe "index" do
    test "lists all ranks", %{conn: conn} do
      conn = get(conn, Routes.rank_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Ranks"
    end
  end

  describe "new rank" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.rank_path(conn, :new))
      assert html_response(conn, 200) =~ "New Rank"
    end
  end

  describe "create rank" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.rank_path(conn, :create), rank: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.rank_path(conn, :show, id)

      conn = get(conn, Routes.rank_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Rank"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.rank_path(conn, :create), rank: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Rank"
    end
  end

  describe "edit rank" do
    setup [:create_rank]

    test "renders form for editing chosen rank", %{conn: conn, rank: rank} do
      conn = get(conn, Routes.rank_path(conn, :edit, rank))
      assert html_response(conn, 200) =~ "Edit Rank"
    end
  end

  describe "update rank" do
    setup [:create_rank]

    test "redirects when data is valid", %{conn: conn, rank: rank} do
      conn = put(conn, Routes.rank_path(conn, :update, rank), rank: @update_attrs)
      assert redirected_to(conn) == Routes.rank_path(conn, :show, rank)

      conn = get(conn, Routes.rank_path(conn, :show, rank))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, rank: rank} do
      conn = put(conn, Routes.rank_path(conn, :update, rank), rank: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Rank"
    end
  end

  describe "delete rank" do
    setup [:create_rank]

    test "deletes chosen rank", %{conn: conn, rank: rank} do
      conn = delete(conn, Routes.rank_path(conn, :delete, rank))
      assert redirected_to(conn) == Routes.rank_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.rank_path(conn, :show, rank))
      end
    end
  end

  defp create_rank(_) do
    rank = fixture(:rank)
    {:ok, rank: rank}
  end
end
