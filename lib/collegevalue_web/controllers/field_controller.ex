defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Colleges
  alias Collegevalue.Colleges.Field

  def index(conn, params) do

    sort = params["sort"] || "name"
    sort_dir = params["sort_dir"] || "asc"

    fields = Colleges.list_fields(sort, sort_dir)
    # IO.inspect(fields)
    render(conn, "index.html", fields: fields)
  end

  def new(conn, _params) do
    changeset = Colleges.change_field(%Field{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"field" => field_params}) do
    case Colleges.create_field(field_params) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field created successfully.")
        |> redirect(to: Routes.field_path(conn, :show, field))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    field = Colleges.get_field!(id)
    render(conn, "show.html", field: field)
  end

  def edit(conn, %{"id" => id}) do
    field = Colleges.get_field!(id)
    changeset = Colleges.change_field(field)
    render(conn, "edit.html", field: field, changeset: changeset)
  end

  def update(conn, %{"id" => id, "field" => field_params}) do
    field = Colleges.get_field!(id)

    case Colleges.update_field(field, field_params) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field updated successfully.")
        |> redirect(to: Routes.field_path(conn, :show, field))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", field: field, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    field = Colleges.get_field!(id)
    {:ok, _field} = Colleges.delete_field(field)

    conn
    |> put_flash(:info, "Field deleted successfully.")
    |> redirect(to: Routes.field_path(conn, :index))
  end
end
