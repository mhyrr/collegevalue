defmodule Collegevalue.IndexNow do
  @moduledoc """
  Submits changed URLs to IndexNow, which shares them with Bing, Yandex,
  Naver, Seznam and Yep. Google doesn't take part. Bing's index feeds
  ChatGPT search and Copilot, so this is how a changed page reaches AI
  answers quickly.

  The site serves its key at `/<key>.txt` (`SitemapController.indexnow_key/2`).
  IndexNow takes up to 10,000 URLs a request, all on the key's host.

  Uses Erlang's `:httpc`, so the site needs no HTTP client dependency.
  """

  @endpoint ~c"https://api.indexnow.org/indexnow"
  @batch 10_000

  @doc "The JSON body for one batch of `urls` on `origin`'s host."
  def payload(origin, key, urls) do
    %{
      host: URI.parse(origin).host,
      key: key,
      keyLocation: origin <> "/" <> key <> ".txt",
      urlList: urls
    }
  end

  @doc """
  Submits `urls`, in batches. Returns `{:ok, statuses}` with IndexNow's HTTP
  status per batch (200 or 202 is accepted), or `{:error, reason}`.
  """
  def submit(origin, urls, key \\ Application.fetch_env!(:collegevalue, :indexnow_key)) do
    urls
    |> Enum.chunk_every(@batch)
    |> Enum.reduce_while({:ok, []}, fn batch, {:ok, statuses} ->
      body = origin |> payload(key, batch) |> Jason.encode!()

      case request(:post, {@endpoint, [], ~c"application/json; charset=utf-8", body}) do
        {:ok, {{_, status, _}, _, _}} -> {:cont, {:ok, statuses ++ [status]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc "GETs `url` and returns its body, for reading the live sitemaps."
  def get(url) do
    case request(:get, {String.to_charlist(url), []}) do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, to_string(body)}
      {:ok, {{_, status, _}, _, _}} -> {:error, {:status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  The `<loc>` of each entry in a sitemap or sitemap index whose `<lastmod>`
  is on or after `since`. An entry with no lastmod counts as changed.
  """
  def changed_locs(xml, %Date{} = since) do
    ~r{<(?:url|sitemap)>\s*<loc>([^<]+)</loc>(?:\s*<lastmod>([^<]+)</lastmod>)?}
    |> Regex.scan(xml)
    |> Enum.filter(fn
      [_, _loc] -> true
      [_, _loc, lastmod] -> Date.compare(lastmod |> String.slice(0, 10) |> Date.from_iso8601!(), since) != :lt
    end)
    |> Enum.map(fn [_, loc | _] -> unescape(loc) end)
  end

  defp unescape(text), do: text |> String.replace("&lt;", "<") |> String.replace("&gt;", ">") |> String.replace("&amp;", "&")

  defp request(method, request) do
    {:ok, _} = Application.ensure_all_started([:inets, :ssl])

    ssl = [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
    ]

    :httpc.request(method, request, [ssl: ssl, timeout: 60_000], body_format: :binary)
  end
end
