defmodule CollegevalueWeb.CollegeControllerTest do
  use CollegevalueWeb.ConnCase

  alias Collegevalue.Colleges

  @create_attrs %{accreditation: "some accreditation", city: "some city", control: "some control", name: "some name", opeid: 42, state: "some state", unitid: 42, url: "some url", zip: "some zip"}
  @update_attrs %{accreditation: "some updated accreditation", city: "some updated city", control: "some updated control", name: "some updated name", opeid: 43, state: "some updated state", unitid: 43, url: "some updated url", zip: "some updated zip"}
  @invalid_attrs %{accreditation: nil, city: nil, control: nil, name: nil, opeid: nil, state: nil, unitid: nil, url: nil, zip: nil}

  def fixture(:college) do
    {:ok, college} = Colleges.create_college(@create_attrs)
    college
  end

  describe "index" do
    test "lists all colleges", %{conn: conn} do
      conn = get(conn, Routes.college_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Colleges"
    end
  end

  describe "new college" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.college_path(conn, :new))
      assert html_response(conn, 200) =~ "New College"
    end
  end

  describe "create college" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.college_path(conn, :create), college: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.college_path(conn, :show, id)

      conn = get(conn, Routes.college_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show College"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.college_path(conn, :create), college: @invalid_attrs)
      assert html_response(conn, 200) =~ "New College"
    end
  end

  describe "edit college" do
    setup [:create_college]

    test "renders form for editing chosen college", %{conn: conn, college: college} do
      conn = get(conn, Routes.college_path(conn, :edit, college))
      assert html_response(conn, 200) =~ "Edit College"
    end
  end

  describe "update college" do
    setup [:create_college]

    test "redirects when data is valid", %{conn: conn, college: college} do
      conn = put(conn, Routes.college_path(conn, :update, college), college: @update_attrs)
      assert redirected_to(conn) == Routes.college_path(conn, :show, college)

      conn = get(conn, Routes.college_path(conn, :show, college))
      assert html_response(conn, 200) =~ "some updated accreditation"
    end

    test "renders errors when data is invalid", %{conn: conn, college: college} do
      conn = put(conn, Routes.college_path(conn, :update, college), college: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit College"
    end
  end

  describe "delete college" do
    setup [:create_college]

    test "deletes chosen college", %{conn: conn, college: college} do
      conn = delete(conn, Routes.college_path(conn, :delete, college))
      assert redirected_to(conn) == Routes.college_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.college_path(conn, :show, college))
      end
    end
  end

  defp create_college(_) do
    college = fixture(:college)
    {:ok, college: college}
  end
end
