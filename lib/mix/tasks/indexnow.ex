defmodule Mix.Tasks.Indexnow do
  @shortdoc "Submits pages changed since a date to IndexNow"
  @moduledoc """
  Reads the live sitemap index and submits to IndexNow every URL in the
  sitemaps changed on or after `--since` (default: today). Run it after a
  deploy that changed pages, once the deploy is live.

      mix indexnow                      # sitemaps changed today
      mix indexnow --since 2026-11-03
      mix indexnow --url /fields/psychology --url /fields/nursing
      mix indexnow --dry-run            # list what it would submit

  `--origin` names the site (default https://collegevalue.co). A sitemap's
  lastmod is set in `CollegevalueWeb.SitemapController`.
  """
  use Mix.Task

  alias Collegevalue.IndexNow

  @switches [since: :string, url: :keep, origin: :string, dry_run: :boolean]

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches)
    origin = opts |> Keyword.get(:origin, "https://collegevalue.co") |> String.trim_trailing("/")
    Mix.Task.run("app.config")

    urls =
      case Keyword.get_values(opts, :url) do
        [] -> changed_urls(origin, since(opts))
        paths -> Enum.map(paths, &absolute(origin, &1))
      end

    cond do
      urls == [] ->
        Mix.shell().info("Nothing changed since #{since(opts)}; nothing to submit.")

      opts[:dry_run] ->
        Enum.each(urls, &Mix.shell().info(&1))
        Mix.shell().info("#{length(urls)} URLs would be submitted (dry run).")

      true ->
        case IndexNow.submit(origin, urls) do
          {:ok, statuses} ->
            if Enum.all?(statuses, &(&1 in [200, 202])) do
              Mix.shell().info("Submitted #{length(urls)} URLs to IndexNow: HTTP #{Enum.join(statuses, ", ")}")
            else
              # 403: key not valid (IndexNow hasn't read /<key>.txt yet, or it
              # doesn't match); 422: a URL off the key's host; 429: too often.
              Mix.raise("IndexNow refused the submission: HTTP #{Enum.join(statuses, ", ")}")
            end

          {:error, reason} -> Mix.raise("IndexNow submit failed: #{inspect(reason)}")
        end
    end
  end

  defp since(opts), do: opts |> Keyword.get(:since, Date.to_iso8601(Date.utc_today())) |> Date.from_iso8601!()

  defp changed_urls(origin, since) do
    index = fetch!(origin <> "/sitemap.xml")

    index
    |> IndexNow.changed_locs(since)
    |> Enum.flat_map(&(&1 |> fetch!() |> IndexNow.changed_locs(since)))
    |> Enum.uniq()
  end

  defp fetch!(url) do
    case IndexNow.get(url) do
      {:ok, body} -> body
      {:error, reason} -> Mix.raise("Couldn't read #{url}: #{inspect(reason)}")
    end
  end

  defp absolute(origin, "/" <> _ = path), do: origin <> path
  defp absolute(_origin, url), do: url
end
