defmodule CollegevalueWeb.Plugs.CanonicalHost do
  @moduledoc """
  Moves GET and HEAD requests on a mirror host (www.collegevalue.co, the
  fly.dev name) permanently to the same path on the public origin,
  `config :collegevalue, :canonical_url`.

  Every mirror served a full copy of the site. The canonical tags pointed
  Google at collegevalue.co, but Googlebot still spent a third of its crawl
  requests on www (Search Console crawl stats, 2026-11-17).

  The mirrors are `config :collegevalue, :mirror_hosts`. With either setting
  missing (dev, test), the plug does nothing. Both can be passed as options,
  `:canonical_url` and `:mirror_hosts`, which win over the config.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{method: method, host: host} = conn, opts) when method in ["GET", "HEAD"] do
    origin = Keyword.get_lazy(opts, :canonical_url, fn -> Application.get_env(:collegevalue, :canonical_url) end)
    mirrors = Keyword.get_lazy(opts, :mirror_hosts, fn -> Application.get_env(:collegevalue, :mirror_hosts, []) end)

    if origin && host in mirrors do
      query = if conn.query_string == "", do: "", else: "?" <> conn.query_string

      conn
      |> put_resp_header("location", origin <> conn.request_path <> query)
      |> send_resp(301, "")
      |> halt()
    else
      conn
    end
  end

  def call(conn, _opts), do: conn
end
