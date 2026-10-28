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
  # The guide's questions about a major as a whole, and their allowed findings.
  @major_findings %{
    "school_matters" => ~w(two_markets some little unclear),
    "who_is_counted" => ~w(new_graduates mixed working_adults unclear),
    "leads_to" => ~w(licensure graduate_school direct_jobs mixed unclear),
    "nearby_pair" => ~w(comparable not_comparable none)
  }

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
  The majors the keyword map targets, by the `/fields/<slug>` pages it names.
  A page whose slug matches no field raises, so a typo in the map can't drop a major.
  """
  def keyword_map_fields(path \\ "docs/seo/keywords.yml") do
    ~r{page:\s*/fields/([^\s#]+)}
    |> Regex.scan(File.read!(path))
    |> Enum.map(fn [_, slug] -> slug end)
    |> Enum.reject(&(&1 == "rank"))
    |> Enum.uniq()
    |> Enum.map(&Collegevalue.Fields.get_field_by_slug!(&1).name)
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

  @doc """
  The text a step's model call is built from: its prompt and the editorial
  guide (`GUIDE.md`) it includes.
  """
  def prompt_template(step) when step in [:research, :note] do
    read = fn file -> case File.read(Path.join(root(), file)), do: ({:ok, text} -> text; _ -> "") end
    {read.("prompts/#{step}.md"), read.("GUIDE.md")}
  end

  @doc """
  A hash of `prompt_template/1`. Output made under another prompt or guide
  is stale, so revising the guide redrafts exactly what it affects.
  """
  def prompt_hash(step), do: step |> prompt_template() |> Facts.stable_hash()

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
  def read_note(name, file \\ "note.md") do
    case File.read(path(name, file)) do
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

  @doc """
  The names of the majors whose note is approved, by short name. The home page
  links these, since they are the field pages with the most to read.
  """
  def approved_fields do
    case File.ls(root()) do
      {:ok, slugs} -> slugs |> Enum.flat_map(&approved_name/1) |> Enum.sort_by(&Collegevalue.Fields.short_name/1)
      {:error, :enoent} -> []
    end
  end

  defp approved_name(slug) do
    dir = Path.join(root(), slug)

    with {:ok, text} <- File.read(Path.join(dir, "note.md")),
         %{meta: %{"status" => "approved"}} <- parse_note(text),
         {:ok, facts} <- File.read(Path.join(dir, "facts.json")) do
      [Jason.decode!(facts)["name"]]
    else
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
    * `:note` — `:missing`, `:stale`, `:draft`, `:approved`, `:rejected`,
      `:approved_stale` (live, but made from older inputs) or `:next_draft`
      (live, with a fresh redraft in `note.next.md` awaiting approval)

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
        research["prompt_hash"] != prompt_hash(:research) -> :stale
        true -> :current
      end

    fresh? = fn note ->
      research_state == :current and note.meta["research_hash"] == research["hash"] and
        note.meta["prompt_hash"] == prompt_hash(:note)
    end

    # An approved note stays live until its replacement is approved: a
    # redraft goes to note.next.md (`:next_draft`), never over it.
    note_state =
      cond do
        is_nil(facts) -> :none
        is_nil(note) -> :missing
        note.meta["status"] == "approved" and fresh?.(note) -> :approved
        note.meta["status"] == "approved" ->
          next = read_note(name, "note.next.md")
          if next && fresh?.(next), do: :next_draft, else: :approved_stale
        not fresh?.(note) -> :stale
        note.meta["status"] == "rejected" -> :rejected
        true -> :draft
      end

    %{name: name, facts: facts, research: research_state, note: note_state}
  end

  @doc "Whether a note in `state` needs drafting."
  def needs_note?(state), do: state in [:missing, :stale, :approved_stale]

  @doc "The file a new draft goes to: beside an approved note, never over it."
  def draft_file(name) do
    case read_note(name) do
      %{meta: %{"status" => "approved"}} -> "note.next.md"
      _ -> "note.md"
    end
  end

  ## Checks on model output

  @doc """
  Checks a research reply against the facts it was made from: one entry per
  flagged program, each with a known cause, short evidence and, unless the
  cause needs none, an http(s) source. Returns the research to store.
  """
  def check_research(%{"programs" => programs} = reply, facts) when is_list(programs) do
    flagged = MapSet.new(facts.flagged, & &1.unitid)
    unitids = Enum.map(programs, & &1["unitid"])
    major = reply["major"]

    errors =
      major_errors(major) ++
        Enum.flat_map(programs, &program_errors/1) ++
        missing_errors(flagged, MapSet.new(unitids)) ++
        if(length(unitids) != length(Enum.uniq(unitids)), do: ["a program appears twice"], else: [])

    if errors == [] do
      research = %{
        "field" => facts.name,
        "facts_hash" => facts.hash,
        "prompt_hash" => prompt_hash(:research),
        "major" => Map.new(major, fn {key, answer} -> {key, Map.take(answer, ~w(finding evidence source))} end),
        "programs" => Enum.map(programs, &Map.take(&1, ~w(unitid cause evidence source)))
      }

      {:ok, Map.put(research, "hash", hash(research))}
    else
      {:error, errors}
    end
  end

  def check_research(_reply, _facts), do: {:error, ["the reply has no programs list"]}

  defp major_errors(%{} = major) do
    Enum.flat_map(@major_findings, fn {key, findings} ->
      case major[key] do
        %{"finding" => finding, "evidence" => evidence} = answer ->
          source = answer["source"]

          [
            finding not in findings && "major #{key}: unknown finding #{inspect(finding)}",
            !(is_binary(evidence) and evidence != "" and String.length(evidence) <= @evidence_max) &&
              "major #{key}: evidence missing or over #{@evidence_max} characters",
            finding in findings and finding not in ~w(unclear none) and
              not (is_binary(source) and source =~ ~r{^https?://}) &&
              "major #{key}: finding #{finding} needs an http(s) source"
          ]
          |> Enum.filter(&is_binary/1)

        _ ->
          ["major: no #{key} answer"]
      end
    end)
  end

  defp major_errors(_major), do: ["the reply has no major section"]

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
  Checks a note's text: two paragraphs of one to three sentences (see
  GUIDE.md), and no number the facts don't hold. The model interprets; it never computes.

  A number may also be a fact's dollar figure rounded to the nearest $500 or
  $1,000 ("about $71,000"), one of the site's own labels (the income brackets,
  the admission bands, four years), or a number in the research's sourced
  evidence on the major as a whole (the CPA's 150 credit hours).
  """
  def check_note(body, facts, research \\ nil) do
    allowed = facts |> allowed_numbers() |> MapSet.union(research_numbers(research))
    paragraphs = String.split(String.trim(body), ~r/\n\s*\n/, trim: true)
    sentences = Enum.map(paragraphs, &sentence_count/1)

    stray =
      ~r/\d[\d,]*(?:\.\d+)?/
      |> Regex.scan(body)
      |> List.flatten()
      |> Enum.map(&String.replace(&1, ",", ""))
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.uniq()

    errors =
      [
        length(paragraphs) != 2 && "#{length(paragraphs)} paragraphs; a note has 2",
        Enum.any?(sentences, &(&1 not in 1..3)) &&
          "paragraphs of #{Enum.join(sentences, " and ")} sentences; each has 1 to 3",
        stray != [] && "numbers not in the facts: #{Enum.join(stray, ", ")}"
      ]
      |> Enum.filter(&is_binary/1)

    if errors == [], do: :ok, else: {:error, errors}
  end

  @doc """
  The sentences in `text`. A period after an initial ("Ana G. Mendez") or a
  common abbreviation ("U.S.", "St. Louis") doesn't end one.
  """
  def sentence_count(text) do
    text
    |> String.replace(~r/\b(?:U\.S|St|Mt|Ft|Dr|Jr|Sr|Inc|vs)\./, "\\0~")
    |> String.replace(~r/\b[A-Z]\./, "\\0~")
    |> String.split(~r/(?<=[.!?])\s+/, trim: true)
    |> length()
  end

  # The family-income brackets ($0-30,000, $48,000-75,000, $110,000 or more),
  # the admission-band edges (10, 25 and 60 percent) and the four years the
  # cost figures assume.
  @site_labels MapSet.new(~w(0 30000 48000 75000 110000 10 25 60 4))

  defp allowed_numbers(facts) do
    facts
    |> Map.delete(:hash)
    |> collect_numbers()
    |> Enum.flat_map(fn
      n when is_float(n) -> [Float.to_string(n), :erlang.float_to_binary(n, decimals: 1)]
      n -> Enum.map([n | rounded(n)], &Integer.to_string/1)
    end)
    |> MapSet.new()
    |> MapSet.union(MapSet.new(~w(1 2 3 10)))
    |> MapSet.union(@site_labels)
  end

  defp rounded(n) when is_integer(n) and n >= 1000, do: [div(n + 250, 500) * 500, div(n + 500, 1000) * 1000]
  defp rounded(_n), do: []

  # Numbers in the sourced evidence on the major as a whole. The program
  # evidence carries no figures (the research prompt forbids them).
  defp research_numbers(%{"major" => %{} = major}) do
    major
    |> Map.values()
    |> Enum.filter(&(is_map(&1) and is_binary(&1["source"]) and is_binary(&1["evidence"])))
    |> Enum.flat_map(&Regex.scan(~r/\d[\d,]*(?:\.\d+)?/, &1["evidence"]))
    |> List.flatten()
    |> MapSet.new(&String.replace(&1, ",", ""))
  end

  defp research_numbers(_research), do: MapSet.new()

  defp collect_numbers(n) when is_number(n), do: [n]
  defp collect_numbers(%{} = map), do: map |> Map.values() |> Enum.flat_map(&collect_numbers/1)
  defp collect_numbers(list) when is_list(list), do: Enum.flat_map(list, &collect_numbers/1)
  defp collect_numbers(_other), do: []

  defp hash(term), do: Facts.stable_hash(term)
end
