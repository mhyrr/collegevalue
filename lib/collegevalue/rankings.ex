defmodule Collegevalue.Rankings do
  @moduledoc """
  The Rankings context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Repo

  alias Collegevalue.Rankings.Rank

  @doc """
  Returns the list of ranks.

  ## Examples

      iex> list_ranks()
      [%Rank{}, ...]

  """
  def list_ranks do
    Repo.all(Rank)
  end

  @doc """
  Gets a single rank.

  Raises `Ecto.NoResultsError` if the Rank does not exist.

  ## Examples

      iex> get_rank!(123)
      %Rank{}

      iex> get_rank!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rank!(id), do: Repo.get!(Rank, id)

  @doc """
  Creates a rank.

  ## Examples

      iex> create_rank(%{field: value})
      {:ok, %Rank{}}

      iex> create_rank(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rank(attrs \\ %{}) do
    %Rank{}
    |> Rank.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a rank.

  ## Examples

      iex> update_rank(rank, %{field: new_value})
      {:ok, %Rank{}}

      iex> update_rank(rank, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rank(%Rank{} = rank, attrs) do
    rank
    |> Rank.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Rank.

  ## Examples

      iex> delete_rank(rank)
      {:ok, %Rank{}}

      iex> delete_rank(rank)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rank(%Rank{} = rank) do
    Repo.delete(rank)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rank changes.

  ## Examples

      iex> change_rank(rank)
      %Ecto.Changeset{source: %Rank{}}

  """
  def change_rank(%Rank{} = rank) do
    Rank.changeset(rank, %{})
  end
end
