defmodule Collegevalue.Colleges do
  @moduledoc """
  The Colleges context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Adapters.SQL
  alias Collegevalue.{Repo, Pagination}
  alias Collegevalue.Colleges.College


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

  def list_disciplines(:ranked) do


    # This needs to be another schema/view

    # Dump this into an ets table later
    case SQL.query(Repo, "select name, avg(case when debt_mean > 0 then debt_mean end) as debt_avg, min(case when debt_mean > 0 then debt_mean end) as debt_min, max(case when debt_mean > 0 then debt_mean end) as debt_max, avg(case when earnings > 0 then earnings end) as earn_avg, min(case when earnings > 0 then earnings end) as earn_min, max(case when earnings > 0 then earnings end) as earn_max, array_agg( distinct credential_level)  from disciplines where credential_level = 3 group by name order by earn_avg DESC") do
      {:ok, result} ->
        disc = %{name: :string, debt_avg: :decimal, debt_min: :integer, debt_max: :integer, earn_avg: :decimal, earn_min: :integer, earn_max: :integer, array_agg: {:array, :integer}}
        Enum.map(result.rows, &Collegevalue.Repo.load(disc, {result.columns, &1}))
      {:error, err} ->
        err
    end

    # Another select d.debt_mean, d.earnings, c.name, d.credential_level  from disciplines d, colleges c where d.college_id = c.id and d.name = 'Business/Commerce, General.' order by earnings DESC;

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
