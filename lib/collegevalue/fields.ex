defmodule Collegevalue.Fields do
  @moduledoc """
  The Fields context.
  """

  import Ecto.Query, warn: false
  alias Collegevalue.Colleges.{College, Discipline}
  alias Collegevalue.Fields.{Field, Rank}
  alias Collegevalue.Repo

  def list_fields do

    Repo.all(Field)

    # This needs to be another schema/view

    # Dump this into an ets table later
    # Another select d.debt_mean, d.earnings, c.name, d.credential_level  from disciplines d, colleges c where d.college_id = c.id and d.name = 'Business/Commerce, General.' order by earnings DESC;

  end

  def list_fields(col, order) when is_binary(col) and is_binary(order) do

    sort = String.to_atom(col)
    sort_order = String.to_existing_atom(order)

    Field
    |> order_by({^sort_order, ^sort} )
    |> Repo.all()

  end

  def match_fields_by_name(name) do

    like = "%#{name}%"

    query = from f in Field,
      where: ilike(f.name, ^like),
      select: f.name,
      limit: 10
    Repo.all(query)

  end

  def match_fields(name) do

    like = "%#{name}%"

    query = from f in Field,
      where: ilike(f.name, ^like),
      order_by: [{:asc, :name}]
    Repo.all(query)

  end

  def get_field!(name), do: Repo.get_by!(Field, name: name)

  # Short names, reviewed by hand: what a student searches, not Scorecard's
  # CIP title. A field missing from the file gets `default_short_name/1`.
  # The short name makes the slug, and a slug is permanent once live:
  # renaming one means another redirect.
  @short_names_path Path.expand("../../priv/fields/short_names.json", __DIR__)
  @external_resource @short_names_path
  @short_names @short_names_path |> File.read!() |> Jason.decode!()

  # The slugs that were live from 2026-10-23 to the short names. Kept so
  # those URLs 301 to the new ones.
  @legacy_slugs %{
    "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing" => "nursing",
    "Nursing" => "nursing-other",
    "Business Administration, Management and Operations" => "business",
    "English Language and Literature, General" => "english"
  }

  @doc """
  The name the site shows for a field: "Nursing" for Scorecard's
  "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing".
  """
  def short_name(name), do: Map.get_lazy(@short_names, name, fn -> default_short_name(name) end)

  defp default_short_name(name) do
    name
    |> String.replace(~r/,\s*General\.?$/, "")
    |> String.replace(~r/,\s*Other$/, " (Other)")
  end

  @doc """
  The field's URL segment: its short name in lowercase words joined by hyphens.

      iex> Collegevalue.Fields.slug("Psychology, General")
      "psychology"
  """
  def slug(name), do: slugify(short_name(name))

  @doc "The slug a field had before short names, which now redirects."
  def legacy_slug(name) do
    Map.get_lazy(@legacy_slugs, name, fn -> name |> String.replace(~r/,\s*General\.?$/, "") |> slugify() end)
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  @doc """
  What a `/fields/<segment>` URL points at: `{:ok, name}` for a current slug,
  `{:moved, slug}` for an old name URL or a legacy slug, `:error` for neither.
  `segment` is decoded.
  """
  def resolve_field_segment(segment) do
    names = Field |> select([f], f.name) |> Repo.all()

    cond do
      name = Enum.find(names, &(slug(&1) == segment)) -> {:ok, name}
      name = Enum.find(names, &(&1 == segment or legacy_slug(&1) == segment)) -> {:moved, slug(name)}
      true -> :error
    end
  end

  @doc "The field whose `slug/1` is `slug`. Raises `Ecto.NoResultsError` (a 404) when none is."
  def get_field_by_slug!(slug) do
    case resolve_field_segment(slug) do
      {:ok, name} -> get_field!(name)
      _ -> raise Ecto.NoResultsError, queryable: Field
    end
  end

  @doc """
  Whether any college reports debt or earnings for the field. A field without
  either has a page with nothing on it but a list of names, so it stays out of
  the search index and the sitemap.
  """
  def has_outcomes?(%Field{debt_avg: debt, earn_avg: earn}), do: positive?(debt) or positive?(earn)

  @doc """
  The name of every field that `has_outcomes?/1`, ordered by name.
  """
  def list_indexable_field_names do
    Field
    |> where([f], f.debt_avg > 0 or f.earn_avg > 0)
    |> order_by(asc: :name)
    |> select([f], f.name)
    |> Repo.all()
  end

  defp positive?(%Decimal{} = value), do: Decimal.gt?(value, 0)
  defp positive?(value) when is_number(value), do: value > 0
  defp positive?(_value), do: false

  @doc """
  Bachelor's programs ranked by first-year earnings alone, highest first for
  `"top"`. A program's debt is its own median federal student-loan debt
  (`stgp_debt_median`), never the college's: a program without one shows no
  debt. `require_debt: true` keeps only programs that report it.
  """
  def get_bachelors_earnings(sort \\ "top", limit \\ 100, opts \\ []) do
    direction = if sort == "top", do: :desc, else: :asc

    query =
      bachelors_ranks()
      |> order_by([_c, d], [{^direction, d.earnings_1yr}, {:asc, d.id}])
      |> limit(^limit)

    query =
      if Keyword.get(opts, :require_debt, false),
        do: where(query, [_c, d], d.stgp_debt_median > 0),
        else: query

    Repo.all(query)
  end

  @doc """
  Bachelor's programs ranked by first-year earnings minus the program's
  median federal student-loan debt, highest first for `"top"`. Only programs
  that report both figures are ranked: a missing debt is never filled in
  with the college's.
  """
  def get_bachelors_debt_earnings(sort \\ "top", limit \\ 100, _opts \\ []) do
    direction = if sort == "top", do: :desc, else: :asc

    bachelors_ranks()
    |> where([_c, d], d.stgp_debt_median > 0)
    |> order_by([_c, d], [{^direction, d.earnings_1yr - d.stgp_debt_median}, {:asc, d.id}])
    |> limit(^limit)
    |> Repo.all()
  end

  # Every bachelor's program that reports first-year earnings, as a `Rank`.
  # Missing Scorecard figures are stored as -1 or -2, so a debt that isn't
  # positive is nil here.
  defp bachelors_ranks do
    from c in College,
      join: d in Discipline,
      on: c.id == d.college_id,
      where: d.credential_level == 3 and d.earnings_1yr > 0,
      select: %Rank{
        field_name: d.name,
        credential_level: d.credential_level,
        cost: fragment("NULLIF(GREATEST(?, 0), 0)", d.stgp_debt_median),
        cost_field: "Debt",
        payoff: d.earnings_1yr,
        payoff_field: "Field Earnings",
        diff: fragment("? - NULLIF(GREATEST(?, 0), 0)", d.earnings_1yr, d.stgp_debt_median),
        college_name: c.name,
        unit_id: c.unitid,
        college_id: c.id,
        tuition_out: c.tuition_out,
        tuition_in: c.tuition_in,
        admissions: c.admissions_rate,
        sat_avg: c.sat_avg,
        url: c.url,
        has_major_debt: d.stgp_debt_median > 0
      }
  end
end
