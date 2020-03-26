defmodule CollegevalueWeb.RankController do
  use CollegevalueWeb, :controller

  alias Collegevalue.Rankings
  alias Collegevalue.Rankings.Rank

  def index(conn, _params) do
    ranks = Rankings.list_ranks()
    render(conn, "index.html", ranks: ranks)
  end

  def new(conn, _params) do
    changeset = Rankings.change_rank(%Rank{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"rank" => rank_params}) do
    case Rankings.create_rank(rank_params) do
      {:ok, rank} ->
        conn
        |> put_flash(:info, "Rank created successfully.")
        |> redirect(to: Routes.rank_path(conn, :show, rank))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    rank = Rankings.get_rank!(id)
    render(conn, "show.html", rank: rank)
  end

  def edit(conn, %{"id" => id}) do
    rank = Rankings.get_rank!(id)
    changeset = Rankings.change_rank(rank)
    render(conn, "edit.html", rank: rank, changeset: changeset)
  end

  def update(conn, %{"id" => id, "rank" => rank_params}) do
    rank = Rankings.get_rank!(id)

    case Rankings.update_rank(rank, rank_params) do
      {:ok, rank} ->
        conn
        |> put_flash(:info, "Rank updated successfully.")
        |> redirect(to: Routes.rank_path(conn, :show, rank))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", rank: rank, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    rank = Rankings.get_rank!(id)
    {:ok, _rank} = Rankings.delete_rank(rank)

    conn
    |> put_flash(:info, "Rank deleted successfully.")
    |> redirect(to: Routes.rank_path(conn, :index))
  end
end
