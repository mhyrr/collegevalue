defmodule CollegevalueWeb.StructuredData do
  @moduledoc """
  The schema.org JSON-LD a page carries in its head, built from the page's
  assigns: one `@graph` per page, or nil when the page has nothing to describe.

    * A college page: a `CollegeOrUniversity`, and its breadcrumbs.
    * A field page: an `EducationalOccupationalProgram` for the major as a
      whole, with the median first-year pay across colleges as its
      `salaryUponCompletion`, and its breadcrumbs. A field page is one major
      across ~1,000 colleges; the per-college programs stay in the table,
      since an `ItemList` of them would repeat the table at length and no
      search feature reads one.
    * /data: a `Dataset` based on the College Scorecard.

  Every figure here is one the page itself prints. Scorecard's missing-value
  sentinels (-1, -2, 0) never become properties: `Helpers.no_data?/1` drops
  them, and nil values are dropped before encoding. Pages marked noindex
  get none.
  """

  alias Collegevalue.Colleges.College
  alias Collegevalue.Fields.Field
  alias Collegevalue.Scorecard
  alias CollegevalueWeb.Views.Helpers

  @doc """
  The page's JSON-LD as a map, or nil. `url` is the page's canonical URL and
  `origin` the site's public origin, with no trailing slash.
  """
  def graph(assigns, url, origin) do
    case nodes(assigns, url, origin) do
      [] -> nil
      nodes -> %{"@context" => "https://schema.org", "@graph" => nodes}
    end
  end

  @doc """
  The JSON-LD encoded for a `<script type="application/ld+json">` body, or
  nil. Every `<` is written as `\\u003c`, so no string in the data (a college
  name, say) can close the script tag or open a comment.
  """
  def encode(nil), do: nil
  def encode(graph), do: graph |> Jason.encode!() |> String.replace("<", "\\u003c")

  defp nodes(%{noindex: true}, _url, _origin), do: []

  defp nodes(%{college: %College{} = college}, url, origin) do
    [
      compact(%{
        "@type" => "CollegeOrUniversity",
        "name" => college.name,
        "url" => url,
        "address" => address(college),
        "sameAs" => with({href, _label} <- Helpers.website(college.url), do: href)
      }),
      breadcrumbs(origin, [{"Colleges", "/colleges"}, {college.name, url}])
    ]
  end

  defp nodes(%{field: %Field{name: name}} = assigns, url, origin) do
    short = Helpers.field_short_name(name)
    program = program(short, url, assigns[:facts])
    Enum.reject([program, breadcrumbs(origin, [{"Fields", "/fields"}, {short, url}])], &is_nil/1)
  end

  defp nodes(%{dataset: true}, url, origin) do
    [
      %{
        "@type" => "Dataset",
        "name" => "CollegeValue: College Cost vs. Earnings by School and Major",
        "description" =>
          "What every U.S. college and bachelor's major costs, what its graduates borrow and what they earn, " <>
            "taken from the U.S. Department of Education's College Scorecard (#{Scorecard.release()} release) " <>
            "and compared college by college and major by major.",
        "url" => url,
        "creator" => %{"@type" => "Organization", "name" => "CollegeValue", "url" => origin <> "/"},
        "license" => CollegevalueWeb.OpenData.license().url,
        "isAccessibleForFree" => true,
        "distribution" =>
          for name <- CollegevalueWeb.OpenData.datasets(), {format, type} <- [{"csv", "text/csv"}, {"json", "application/json"}] do
            %{
              "@type" => "DataDownload",
              "name" => CollegevalueWeb.OpenData.title(name),
              "encodingFormat" => type,
              "contentUrl" => origin <> "/data/#{name}.#{format}"
            }
          end,
        "isBasedOn" => %{
          "@type" => "Dataset",
          "name" => "College Scorecard",
          "url" => Scorecard.url(),
          "datePublished" => Scorecard.release_date(),
          "creator" => %{"@type" => "GovernmentOrganization", "name" => Scorecard.publisher()}
        }
      }
    ]
  end

  defp nodes(_assigns, _url, _origin), do: []

  # The major as one program: its median first-year pay across the colleges
  # that report it, and the middle half when the page shows it (four or more
  # programs, as in `Helpers.field_answer/1`).
  defp program(name, url, %{earnings_median: median} = facts) when is_number(median) do
    quartiles = facts.programs_with_earnings >= 4

    %{
      "@type" => "EducationalOccupationalProgram",
      "name" => "#{name} (bachelor's degree)",
      "url" => url,
      "educationalCredentialAwarded" => "Bachelor's degree",
      "salaryUponCompletion" =>
        compact(%{
          "@type" => "MonetaryAmountDistribution",
          "name" =>
            "Median earnings one year after graduation, across #{facts.programs_with_earnings} bachelor's " <>
              if(facts.programs_with_earnings == 1, do: "program", else: "programs"),
          "currency" => "USD",
          "duration" => "P1Y",
          "median" => median,
          "percentile25" => quartiles && amount(facts[:earnings_p25]),
          "percentile75" => quartiles && amount(facts[:earnings_p75])
        })
    }
  end

  defp program(_name, _url, _facts), do: nil

  defp address(%College{city: city, state: state} = college) do
    if Helpers.place(college) do
      %{"@type" => "PostalAddress", "addressLocality" => city, "addressRegion" => state, "addressCountry" => "US"}
    end
  end

  # Home, then each {name, path or URL}; the last is the page itself.
  defp breadcrumbs(origin, trail) do
    items =
      [{"Home", "/"} | trail]
      |> Enum.with_index(1)
      |> Enum.map(fn {{name, link}, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => name,
          "item" => if(String.starts_with?(link, "/"), do: origin <> link, else: link)
        }
      end)

    %{"@type" => "BreadcrumbList", "itemListElement" => items}
  end

  defp amount(value), do: if(is_number(value) and not Helpers.no_data?(value), do: value)

  defp compact(map), do: map |> Enum.reject(fn {_key, value} -> value in [nil, false] end) |> Map.new()
end
