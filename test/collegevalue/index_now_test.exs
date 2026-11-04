defmodule Collegevalue.IndexNowTest do
  use ExUnit.Case, async: true

  alias Collegevalue.IndexNow

  test "the payload names the host and where the key lives" do
    assert IndexNow.payload("https://collegevalue.co", "abc", ["https://collegevalue.co/fields/psychology"]) == %{
             host: "collegevalue.co",
             key: "abc",
             keyLocation: "https://collegevalue.co/abc.txt",
             urlList: ["https://collegevalue.co/fields/psychology"]
           }
  end

  describe "changed_locs/2" do
    @xml """
    <urlset>
      <url><loc>https://collegevalue.co/fields/psychology</loc><lastmod>2026-11-03</lastmod></url>
      <url><loc>https://collegevalue.co/fields/rank</loc><lastmod>2026-11-02</lastmod></url>
      <url><loc>https://collegevalue.co/colleges?page=2&amp;x=1</loc></url>
    </urlset>
    """

    test "keeps entries changed on or after the date, and entries with no lastmod" do
      assert IndexNow.changed_locs(@xml, ~D[2026-11-03]) == [
               "https://collegevalue.co/fields/psychology",
               "https://collegevalue.co/colleges?page=2&x=1"
             ]
    end

    test "reads a sitemap index the same way" do
      index = ~s(<sitemapindex><sitemap><loc>https://collegevalue.co/sitemap-fields.xml</loc><lastmod>2026-11-03T00:00:00Z</lastmod></sitemap></sitemapindex>)

      assert IndexNow.changed_locs(index, ~D[2026-11-03]) == ["https://collegevalue.co/sitemap-fields.xml"]
      assert IndexNow.changed_locs(index, ~D[2026-11-04]) == []
    end
  end
end
