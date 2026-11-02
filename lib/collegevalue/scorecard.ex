defmodule Collegevalue.Scorecard do
  @moduledoc """
  Which College Scorecard release the site's numbers come from. Every page
  that states the source, and the /data page, read it from here, so a data
  reload changes it in one place.

  The release is the October 2024 one: commit 1cd6e31 added
  `data/Most-Recent-Cohorts-Institution_new.csv` and
  `data/Most-Recent-Cohorts-Field-of-Study_new.csv` as "the DOE College
  Scorecard October 2024 release", `priv/repo/seeds.exs` loads those two
  files, and the /data page says the same. `@loaded` is when the site
  switched to them (commit d1fcfcb, 2026-02-23).
  """

  @release "October 2024"
  @release_month "2024-10"
  @loaded "February 2026"

  @publisher "U.S. Department of Education"
  @url "https://collegescorecard.ed.gov/data/"

  @doc ~S|The release as people say it: "October 2024".|
  def release, do: @release

  @doc ~S|The release as an ISO 8601 month, for structured data: "2024-10".|
  def release_month, do: @release_month

  @doc ~S|When the site loaded this release: "February 2026".|
  def loaded, do: @loaded

  def publisher, do: @publisher
  def url, do: @url
end
