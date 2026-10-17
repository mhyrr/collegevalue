defmodule CollegevalueWeb.PageControllerTest do
  use CollegevalueWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<title data-suffix=\" · CollegeValue\">College Cost vs. Benefit by School and Major · CollegeValue</title>"
  end
end
