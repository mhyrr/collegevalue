defmodule CollegevalueWeb.Plugs.FieldSlugRedirect do
  @moduledoc """
  Field pages lived at `/fields/<Scorecard name>` (`/fields/Psychology%2C%20General`)
  before they moved to slugs (`/fields/psychology`). Search engines and old
  links still ask for the name URLs, so this sends each to its slug with a
  301, which carries the old URL's standing over. The query string is kept.

  A LiveView redirect would answer 302, so the redirect lives here, ahead of
  the route.
  """
  import Plug.Conn

  alias Collegevalue.Fields

  @reserved ~w(rank you)

  def init(opts), do: opts

  def call(%{path_info: ["fields", segment]} = conn, _opts) when segment not in @reserved do
    name = URI.decode(segment)

    with false <- Fields.slug?(name),
         {:ok, field} <- find(name) do
      query = if conn.query_string == "", do: "", else: "?" <> conn.query_string

      conn
      |> put_resp_header("location", "/fields/" <> Fields.slug(field.name) <> query)
      |> send_resp(301, "")
      |> halt()
    else
      _ -> conn
    end
  end

  def call(conn, _opts), do: conn

  # An unknown name falls through to the route, which answers 404.
  defp find(name) do
    {:ok, Fields.get_field!(name)}
  rescue
    Ecto.NoResultsError -> :error
  end
end
