defmodule CollegevalueWeb.PageController do
  use CollegevalueWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
