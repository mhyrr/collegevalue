defmodule Collegevalue.FieldNotes do
  @moduledoc """
  Short, reviewed notes on what a major's numbers hide, stored as files under
  `priv/field_notes/<slug>/`:

    * `facts.json`: `Collegevalue.FieldNotes.Facts` for the major, with its hash.
    * `research.json`: per flagged program, a cause from `causes/0`, one sentence
      of evidence and a source. Written by a model, checked by `check_research/2`.
    * `note.md`: front matter plus two or three sentences. Written by a model,
      checked by `check_note/2`, then edited and approved by a person.

  Only a note with `status: approved` reaches the page. Each step records the
  hash of what it was made from, so `status/1` knows what is stale and the
  runner never pays twice for the same input.
  See docs/plans/2026-10-22-field-notes-design.md.
  """

  alias Collegevalue.FieldNotes.Facts

  @causes ~w(experienced_students online_adult small_cohort selective_school high_cost_region
             low_cost_region credential_mismatch data_error no_clear_cause)
  # Causes a reader can verify from the facts alone, so they need no source.
  @sourceless ~w(small_cohort data_error no_clear_cause)
  @evidence_max 280

  def causes, do: @causes

  def slug(name) do
    name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")
  end

  @doc "The directory notes are read from; `priv/field_notes` unless configured."
  def root do
    Application.get_env(:collegevalue, :field_notes_root) ||
      Application.app_dir(:collegevalue, "priv/field_notes")
  end

  def path(name, file), do: Path.join([root(), slug(name), file])

  @doc """
  The majors the keyword map targets, by the `/fields/<name>` pages it names.
  """
  def keyword_map_fields(path \\ "docs/seo/keywords.yml") do
    ~r{page:\s*/fields/([^\s#]+)}
    |> Regex.scan(File.read!(path))
    |> Enum.map(fn [_, encoded] -> URI.decode(encoded) end)
    |> Enum.reject(&(&1 == "rank"))
    |> Enum.uniq()
  end

  @doc """
  The majors a task should act on: the names given, plus the keyword-map
  majors with `--keyword-map`. Never every major: adding majors is a choice.
  """
  def select_fields(names, opts) do
    keyword = if opts[:keyword_map], do: keyword_map_fields(), else: []
    Enum.uniq(keyword ++ names)
  end

  @doc "Writes `facts` to `facts.json`, creating the major's directory."
  def write_facts(facts) do
    write!(facts.name, "facts.json", Jason.encode_to_iodata!(facts, pretty: true))
  end

  def write!(name, file, contents) do
    target = path(name, file)
    File.mkdir_p!(Path.dirname(target))
    File.write!(target, contents)
    target
  end

  ## Reading

  def read_json(name, file) do
    case File.read(path(name, file)) do
      {:ok, body} -> Jason.decode!(body)
      {:error, :enoent} -> nil
    end
  end

  @doc """
  The note for `name` as `%{meta: map, body: string}`, or `nil` when there is
  none.
  """
  def read_note(name) do
    case File.read(path(name, "note.md")) do
      {:ok, text} -> parse_note(text)
      {:error, :enoent} -> nil
    end
  end

  @doc "The note's paragraphs when it is approved, else `[]`."
  def approved_paragraphs(name) do
    case read_note(name) do
      %{meta: %{"status" => "approved"}, body: body} -> String.split(body, ~r/\n\s*\n/, trim: true)
      _ -> []
    end
  end

  def parse_note(text) do
    case String.split(text, ~r/^---\s*$/m, parts: 3) do
      ["", front, body] ->
        meta =
          for line <- String.split(front, "\n", trim: true),
              [key, value] <- [String.split(line, ":", parts: 2)],
              into: %{},
              do: {String.trim(key), String.trim(value)}

        %{meta: meta, body: String.trim(body)}

      _ ->
        %{meta: %{}, body: String.trim(text)}
    end
  end

  def render_note(meta, body) do
    front = Enum.map_join(meta, "\n", fn {key, value} -> "#{key}: #{value}" end)
    "---\n#{front}\n---\n\n#{String.trim(body)}\n"
  end

  ## Status

  @doc """
  What `name` needs, comparing the stored hashes with the current facts:

    * `:research` — `:missing`, `:stale` or `:current`
    * `:note` — `:missing`, `:stale`, `:draft`, `:approved` or `:rejected`

  A major with no earnings data has `facts: nil` and needs nothing.
  """
  def status(name) do
    facts = Facts.for_field(name)
    research = read_json(name, "research.json")
    note = read_note(name)

    research_state =
      cond do
        is_nil(facts) -> :none
        is_nil(research) -> :missing
        research["facts_hash"] != facts.hash -> :stale
        true -> :current
      end

    note_state =
      cond do
        is_nil(facts) -> :none
        is_nil(note) -> :missing
        research_state != :current -> :stale
        note.meta["research_hash"] != research["hash"] -> :stale
        note.meta["status"] == "approved" -> :approved
        note.meta["status"] == "rejected" -> :rejected
        true -> :draft
      end

    %{name: name, facts: facts, research: research_state, note: note_state}
  end

  ## Checks on model output

  @doc """
  Checks a research reply against the facts it was made from: one entry per
  flagged program, each with a known cause, short evidence and, unless the
  cause needs none, an http(s) source. Returns the research to store.
  """
  def check_research(%{"programs" => programs}, facts) when is_list(programs) do
    flagged = MapSet.new(facts.flagged, & &1.unitid)
    unitids = Enum.map(programs, & &1["unitid"])

    errors =
      Enum.flat_map(programs, &program_errors/1) ++
        missing_errors(flagged, MapSet.new(unitids)) ++
        if(length(unitids) != length(Enum.uniq(unitids)), do: ["a program appears twice"], else: [])

    if errors == [] do
      research = %{
        "field" => facts.name,
        "facts_hash" => facts.hash,
        "programs" => Enum.map(programs, &Map.take(&1, ~w(unitid cause evidence source)))
      }

      {:ok, Map.put(research, "hash", hash(research))}
    else
      {:error, errors}
    end
  end

  def check_research(_reply, _facts), do: {:error, ["the reply has no programs list"]}

  defp program_errors(%{"unitid" => unitid, "cause" => cause, "evidence" => evidence} = program) do
    source = program["source"]

    [
      cause not in @causes && "#{unitid}: unknown cause #{inspect(cause)}",
      !(is_binary(evidence) and evidence != "") && "#{unitid}: no evidence",
      is_binary(evidence) and String.length(evidence) > @evidence_max &&
        "#{unitid}: evidence over #{@evidence_max} characters",
      cause in @causes and cause not in @sourceless and not (is_binary(source) and source =~ ~r{^https?://}) &&
        "#{unitid}: cause #{cause} needs an http(s) source"
    ]
    |> Enum.filter(&is_binary/1)
  end

  defp program_errors(program), do: ["malformed program entry: #{inspect(program)}"]

  defp missing_errors(flagged, seen) do
    missing = MapSet.difference(flagged, seen)
    extra = MapSet.difference(seen, flagged)

    [
      MapSet.size(missing) > 0 && "no entry for flagged #{Enum.join(missing, ", ")}",
      MapSet.size(extra) > 0 && "entries for unflagged #{Enum.join(extra, ", ")}"
    ]
    |> Enum.filter(&is_binary/1)
  end

  @doc """
  Checks a note's text: two to four sentences, and no number the facts don't
  hold. The model interprets; it never computes.
  """
  def check_note(body, facts) do
    allowed = allowed_numbers(facts)
    sentences = body |> String.split(~r/(?<=[.!?])\s+/, trim: true) |> length()

    stray =
      ~r/\d[\d,]*(?:\.\d+)?/
      |> Regex.scan(body)
      |> List.flatten()
      |> Enum.map(&String.replace(&1, ",", ""))
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.uniq()

    errors =
      [
        sentences not in 2..4 && "#{sentences} sentences; a note has 2 to 4",
        stray != [] && "numbers not in the facts: #{Enum.join(stray, ", ")}"
      ]
      |> Enum.filter(&is_binary/1)

    if errors == [], do: :ok, else: {:error, errors}
  end

  defp allowed_numbers(facts) do
    facts
    |> Map.delete(:hash)
    |> collect_numbers()
    |> Enum.flat_map(fn
      n when is_float(n) -> [Float.to_string(n), :erlang.float_to_binary(n, decimals: 1)]
      n -> [Integer.to_string(n)]
    end)
    |> MapSet.new()
    |> MapSet.union(MapSet.new(~w(1 2 3 10)))
  end

  defp collect_numbers(n) when is_number(n), do: [n]
  defp collect_numbers(%{} = map), do: map |> Map.values() |> Enum.flat_map(&collect_numbers/1)
  defp collect_numbers(list) when is_list(list), do: Enum.flat_map(list, &collect_numbers/1)
  defp collect_numbers(_other), do: []

  defp hash(term) do
    :crypto.hash(:sha256, :erlang.term_to_binary(term)) |> Base.encode16(case: :lower) |> binary_part(0, 12)
  end
end
