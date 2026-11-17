defmodule CollegevalueWeb.Plugs.CanonicalHostTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias CollegevalueWeb.Plugs.CanonicalHost

  @opts [canonical_url: "https://collegevalue.co", mirror_hosts: ["www.collegevalue.co", "collegevalue.fly.dev"]]

  defp request(method, url, opts \\ @opts), do: conn(method, url) |> CanonicalHost.call(opts)

  test "a page on www moves permanently to the same path and query on the public origin" do
    conn = request(:get, "https://www.collegevalue.co/fields/rank?rank=parent_loans")

    assert conn.halted
    assert conn.status == 301
    assert get_resp_header(conn, "location") == ["https://collegevalue.co/fields/rank?rank=parent_loans"]
  end

  test "the fly.dev name moves too, sitemap and robots.txt included" do
    for path <- ["/", "/sitemap.xml", "/robots.txt"] do
      conn = request(:get, "https://collegevalue.fly.dev" <> path)
      assert get_resp_header(conn, "location") == ["https://collegevalue.co" <> path]
    end
  end

  test "the public origin, other hosts and non-GET requests pass through" do
    refute request(:get, "https://collegevalue.co/fields/psychology").halted
    refute request(:get, "http://localhost:4000/").halted
    refute request(:post, "https://www.collegevalue.co/search").halted
  end

  test "does nothing without a public origin configured" do
    refute request(:get, "https://www.collegevalue.co/", Keyword.put(@opts, :canonical_url, nil)).halted
  end
end
