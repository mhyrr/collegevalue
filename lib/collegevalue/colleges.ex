defmodule Collegevalue.Colleges do
  @moduledoc """
  The Colleges context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.{Repo, Pagination}
  alias Collegevalue.Colleges.{College, Discipline, Major}


  @doc """
  Returns the list of colleges.

  ## Examples

      iex> list_colleges()
      [%College{}, ...]

  """
  def list_colleges do
    Repo.all(College)
  end


  def list_colleges(a, page \\ 1, per_page \\ 100)

  def list_colleges(:paged, page, per_page) do
    College
    |> order_by(asc: :name)
    |> Pagination.page(page, per_page: per_page)
  end

  def match_colleges_by_name(name) do

    like = "%#{name}%"

    query = from c in College,
      where: ilike(c.name, ^like),
      select: c.name,
      limit: 10
    Repo.all(query)

  end

  def get_majors_by_field(field) do

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.name == ^field,
      select: %Major{
        credential_desc: d.credential_desc,
        credential_level: d.credential_level,
        debt_count: d.debt_count,
        debt_mean: d.debt_mean,
        debt_median: d.debt_median,
        earnings: d.earnings,
        earnings_count: d.earnings_count,
        name: d.name,
        college_name: c.name,
        college_id: c.id,
        url: c.url

      }

    Repo.all(query)

  end


  def get_majors_by_college(college) do

    query = from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: c.name == ^college,
      select: %Major{
        credential_desc: d.credential_desc,
        credential_level: d.credential_level,
        debt_count: d.debt_count,
        debt_mean: d.debt_mean,
        debt_median: d.debt_median,
        earnings: d.earnings,
        earnings_count: d.earnings_count,
        name: d.name,
        college_name: c.name,
        college_id: c.id,
        url: c.url

      }

    Repo.all(query)

  end

  @doc """
  Gets a single college.

  Raises `Ecto.NoResultsError` if the College does not exist.

  ## Examples

      iex> get_college!(123)
      %College{}

      iex> get_college!(456)
      ** (Ecto.NoResultsError)

  """
  def get_college!(id), do: Repo.get!(College, id)

  def get_college(id), do: Repo.get(College, id)

  def get_college_by_name!(name), do: Repo.get_by!(College, name: name)

  def get_college_by_name(name), do: Repo.get_by(College, name: name)

  def get_college_by_opeid!(id), do: Repo.get_by!(College, opeid: id)

  def get_college_by_opeid(id), do: Repo.get_by(College, opeid: id)


  @doc """
  Creates a college.

  ## Examples

      iex> create_college(%{field: value})
      {:ok, %College{}}

      iex> create_college(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_college(attrs \\ %{}) do

    %College{}
    |> College.changeset(attrs)
    |> Repo.insert()

  end

  @doc """
  Updates a college.

  ## Examples

      iex> update_college(college, %{field: new_value})
      {:ok, %College{}}

      iex> update_college(college, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_college(%College{} = college, attrs) do
    college
    |> College.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a College.

  ## Examples

      iex> delete_college(college)
      {:ok, %College{}}

      iex> delete_college(college)
      {:error, %Ecto.Changeset{}}

  """
  def delete_college(%College{} = college) do
    Repo.delete(college)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking college changes.

  ## Examples

      iex> change_college(college)
      %Ecto.Changeset{source: %College{}}

  """
  def change_college(%College{} = college) do
    College.changeset(college, %{})
  end

  alias Collegevalue.Colleges.Discipline

  @doc """
  Returns the list of disciplines.

  ## Examples

      iex> list_disciplines()
      [%Discipline{}, ...]

  """
  def list_disciplines do
    Repo.all(Discipline)
  end

  def list_disciplines(a)

  def list_disciplines(:distinct) do
    Discipline
    |> distinct([d], d.name)
    |> Repo.all
  end

  @doc """
  Gets a single discipline.

  Raises `Ecto.NoResultsError` if the Discipline does not exist.

  ## Examples

      iex> get_discipline!(123)
      %Discipline{}

      iex> get_discipline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_discipline!(id), do: Repo.get!(Discipline, id)

  def get_disciplines_for_college(id) do

    q = from d in Discipline,
      where: d.college_id == ^id,
      select: d

    Repo.all(q)

  end



  @doc """
  Creates a discipline.

  ## Examples

      iex> create_discipline(%{field: value})
      {:ok, %Discipline{}}

      iex> create_discipline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_discipline(attrs \\ %{}) do
    %Discipline{}
    |> Discipline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a discipline.

  ## Examples

      iex> update_discipline(discipline, %{field: new_value})
      {:ok, %Discipline{}}

      iex> update_discipline(discipline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_discipline(%Discipline{} = discipline, attrs) do
    discipline
    |> Discipline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Discipline.

  ## Examples

      iex> delete_discipline(discipline)
      {:ok, %Discipline{}}

      iex> delete_discipline(discipline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_discipline(%Discipline{} = discipline) do
    Repo.delete(discipline)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking discipline changes.

  ## Examples

      iex> change_discipline(discipline)
      %Ecto.Changeset{source: %Discipline{}}

  """
  def change_discipline(%Discipline{} = discipline) do
    Discipline.changeset(discipline, %{})
  end


end
