defmodule CollegevalueWeb.Plugs.FieldSlugRedirect do
  @moduledoc """
  Field pages lived at `/fields/<Scorecard name>` (`/fields/Psychology%2C%20General`),
  then briefly at slugs of the full name (`/fields/accounting-and-related-services`),
  before they moved to slugs of the short name (`/fields/accounting`). Search
  engines and old links still ask for the old URLs, so this sends each to its
  slug with a 301, which carries the old URL's standing over. The query
  string is kept.

  A LiveView redirect would answer 302, so the redirect lives here, ahead of
  the route.
  """
  import Plug.Conn

  alias Collegevalue.Fields

  @reserved ~w(rank you)

  def init(opts), do: opts

  def call(%{path_info: ["fields", segment]} = conn, _opts) when segment not in @reserved do
    case Fields.resolve_field_segment(URI.decode(segment)) do
      {:moved, slug} ->
        query = if conn.query_string == "", do: "", else: "?" <> conn.query_string

        conn
        |> put_resp_header("location", "/fields/" <> slug <> query)
        |> send_resp(301, "")
        |> halt()

      # A current slug renders; an unknown one falls through to a 404.
      _ ->
        conn
    end
  end

  def call(conn, _opts), do: conn
end
