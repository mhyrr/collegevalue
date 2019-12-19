defmodule CollegevalueWeb.FieldControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Colleges

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:field) do
    {:ok, field} = Colleges.create_field(@create_attrs)
    field
  end

  describe "index" do
    test "lists all fields", %{conn: conn} do
      conn = get(conn, Routes.field_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Fields"
    end
  end

  describe "new field" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.field_path(conn, :new))
      assert html_response(conn, 200) =~ "New Field"
    end
  end

  describe "create field" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.field_path(conn, :create), field: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.field_path(conn, :show, id)

      conn = get(conn, Routes.field_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Field"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.field_path(conn, :create), field: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Field"
    end
  end

  describe "edit field" do
    setup [:create_field]

    test "renders form for editing chosen field", %{conn: conn, field: field} do
      conn = get(conn, Routes.field_path(conn, :edit, field))
      assert html_response(conn, 200) =~ "Edit Field"
    end
  end

  describe "update field" do
    setup [:create_field]

    test "redirects when data is valid", %{conn: conn, field: field} do
      conn = put(conn, Routes.field_path(conn, :update, field), field: @update_attrs)
      assert redirected_to(conn) == Routes.field_path(conn, :show, field)

      conn = get(conn, Routes.field_path(conn, :show, field))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, field: field} do
      conn = put(conn, Routes.field_path(conn, :update, field), field: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Field"
    end
  end

  describe "delete field" do
    setup [:create_field]

    test "deletes chosen field", %{conn: conn, field: field} do
      conn = delete(conn, Routes.field_path(conn, :delete, field))
      assert redirected_to(conn) == Routes.field_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.field_path(conn, :show, field))
      end
    end
  end

  defp create_field(_) do
    field = fixture(:field)
    {:ok, field: field}
  end
end
