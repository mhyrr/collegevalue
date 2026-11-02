defmodule Collegevalue.Scorecard do
  @moduledoc """
  Which College Scorecard release the site's numbers come from. Every page
  that states the source, and the /data page, read it from here, so a data
  reload changes it in one place.

  The release is a 2025 one. Commit 1cd6e31 called the files "the DOE College
  Scorecard October 2024 release", but
  `data/Most-Recent-Cohorts-Institution_new.csv` and
  `data/Most-Recent-Cohorts-Field-of-Study_new.csv` are dated October 2025,
  and Greg confirmed 2025 on 2026-11-02. The month isn't known, so only the
  year is stated. `priv/repo/seeds.exs` loads those two files. `@loaded` is
  when the site switched to them (commit d1fcfcb, 2026-02-23).
  """

  @release "2025"
  @release_date "2025"
  @loaded "February 2026"

  @publisher "U.S. Department of Education"
  @url "https://collegescorecard.ed.gov/data/"

  @doc ~S|The release as people say it: "2025".|
  def release, do: @release

  @doc ~S|The release as an ISO 8601 date, for structured data: "2025".|
  def release_date, do: @release_date

  @doc ~S|When the site loaded this release: "February 2026".|
  def loaded, do: @loaded

  def publisher, do: @publisher
  def url, do: @url
end
