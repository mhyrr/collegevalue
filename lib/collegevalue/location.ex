defmodule Collegevalue.Location do
  @moduledoc """
  The Location context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Repo

  alias Collegevalue.Location.Zipcode

  @doc """
  Returns the list of zips.

  ## Examples

      iex> list_zips()
      [%Zipcode{}, ...]

  """
  def list_zips do
    Repo.all(Zipcode)
  end

  @doc """
  Gets a single zipcode.

  Raises `Ecto.NoResultsError` if the Zipcode does not exist.

  ## Examples

      iex> get_zipcode!(123)
      %Zipcode{}

      iex> get_zipcode!(456)
      ** (Ecto.NoResultsError)

  """
  def get_zipcode!(id), do: Repo.get!(Zipcode, id)

  @doc """
  Creates a zipcode.

  ## Examples

      iex> create_zipcode(%{field: value})
      {:ok, %Zipcode{}}

      iex> create_zipcode(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_zipcode(attrs \\ %{}) do
    %Zipcode{}
    |> Zipcode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zipcode.

  ## Examples

      iex> update_zipcode(zipcode, %{field: new_value})
      {:ok, %Zipcode{}}

      iex> update_zipcode(zipcode, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_zipcode(%Zipcode{} = zipcode, attrs) do
    zipcode
    |> Zipcode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zipcode.

  ## Examples

      iex> delete_zipcode(zipcode)
      {:ok, %Zipcode{}}

      iex> delete_zipcode(zipcode)
      {:error, %Ecto.Changeset{}}

  """
  def delete_zipcode(%Zipcode{} = zipcode) do
    Repo.delete(zipcode)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zipcode changes.

  ## Examples

      iex> change_zipcode(zipcode)
      %Ecto.Changeset{data: %Zipcode{}}

  """
  def change_zipcode(%Zipcode{} = zipcode, attrs \\ %{}) do
    Zipcode.changeset(zipcode, attrs)
  end


  def get_location(zipcode) do

    try do
      zip = Repo.get_by!(Zipcode, zipcode: zipcode)

      {zip.latitude, zip.longitude}

    rescue
      err -> IO.inspect(err)
      IO.inspect("couldn't get lat/long from zip")

    end


  end

end
