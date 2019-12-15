defmodule CollegevalueWeb.CollegeController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.College

  def index(conn, params) do

    page = params["page"] || 1
    # per_page = params["per_page"] || 100

    colleges = Colleges.list_colleges(:paged, page)
    render(conn, "index.html", colleges: colleges)
  end

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Colleges.change_college(%College{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"college" => college_params}) do
    case Colleges.create_college(college_params) do
      {:ok, college} ->
        conn
        |> put_flash(:info, "College created successfully.")
        |> redirect(to: Routes.college_path(conn, :show, college))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    college = Colleges.get_college!(id)
    disciplines = Colleges.get_disciplines_for_college(college.id)
    render(conn, "show.html", college: college, disciplines: disciplines)
  end

  def edit(conn, %{"id" => id}) do
    college = Colleges.get_college!(id)
    changeset = Colleges.change_college(college)
    render(conn, "edit.html", college: college, changeset: changeset)
  end

  def update(conn, %{"id" => id, "college" => college_params}) do
    college = Colleges.get_college!(id)

    case Colleges.update_college(college, college_params) do
      {:ok, college} ->
        conn
        |> put_flash(:info, "College updated successfully.")
        |> redirect(to: Routes.college_path(conn, :show, college))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", college: college, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    college = Colleges.get_college!(id)
    {:ok, _college} = Colleges.delete_college(college)

    conn
    |> put_flash(:info, "College deleted successfully.")
    |> redirect(to: Routes.college_path(conn, :index))
  end
end
