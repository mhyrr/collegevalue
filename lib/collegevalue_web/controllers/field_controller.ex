defmodule CollegevalueWeb.FieldController do
  use CollegevalueWeb, :controller

  alias Collegevalue.{Fields, Colleges}

  # def index(conn, params) do

  #   sort = params["sort"] || "name"
  #   sort_dir = params["sort_dir"] || "asc"

  #   fields = Fields.list_fields(sort, sort_dir)
  #   # IO.inspect(fields)
  #   render(conn, "index.html", fields: fields)
  # end


  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    IO.inspect(name)
    field = Fields.get_field!(name)

    majors = Colleges.get_by_field(field.name)
    IO.inspect(majors)
    render(conn, "show.html", field: field, majors: majors)
  end

  def edit(conn, %{"id" => id}) do
    field = Fields.get_field!(id)
    changeset = Fields.change_field(field)
    render(conn, "edit.html", field: field, changeset: changeset)
  end

  def update(conn, %{"id" => id, "field" => field_params}) do
    field = Fields.get_field!(id)

    case Fields.update_field(field, field_params) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field updated successfully.")
        |> redirect(to: Routes.field_path(conn, :show, field))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", field: field, changeset: changeset)
    end
  end

end
