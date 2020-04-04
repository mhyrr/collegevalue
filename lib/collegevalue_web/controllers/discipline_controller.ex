defmodule CollegevalueWeb.DisciplineController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.Discipline

  def index(conn, _params) do
    disciplines = Colleges.list_disciplines(:distinct)
    render(conn, "index.html", disciplines: disciplines)
  end

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Colleges.change_discipline(%Discipline{})
    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"discipline" => discipline_params}) do
    case Colleges.create_discipline(discipline_params) do
      {:ok, discipline} ->
        conn
        |> put_flash(:info, "Discipline created successfully.")
        |> redirect(to: Routes.discipline_path(conn, :show, discipline))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    discipline = Colleges.get_discipline!(id)
    render(conn, "show.html", discipline: discipline)
  end

  def edit(conn, %{"id" => id}) do
    discipline = Colleges.get_discipline!(id)
    changeset = Colleges.change_discipline(discipline)
    render(conn, "edit.html", discipline: discipline, changeset: changeset)
  end

  def update(conn, %{"id" => id, "discipline" => discipline_params}) do
    discipline = Colleges.get_discipline!(id)

    case Colleges.update_discipline(discipline, discipline_params) do
      {:ok, discipline} ->
        conn
        |> put_flash(:info, "Discipline updated successfully.")
        |> redirect(to: Routes.discipline_path(conn, :show, discipline))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", discipline: discipline, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    discipline = Colleges.get_discipline!(id)
    {:ok, _discipline} = Colleges.delete_discipline(discipline)

    conn
    |> put_flash(:info, "Discipline deleted successfully.")
    |> redirect(to: Routes.discipline_path(conn, :index))
  end
end
