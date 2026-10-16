defmodule CollegevalueWeb.PageControllerTest do
  use CollegevalueWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<title data-prefix=\"CV - \">CV - CollegeValue</title>"
  end
end
