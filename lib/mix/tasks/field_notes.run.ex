defmodule Mix.Tasks.FieldNotes.Run do
  @shortdoc "Research and draft notes for the majors named, paying only for what changed"
  @moduledoc """
  Brings each named major's field notes up to date:

    1. writes `facts.json` (free);
    2. researches the flagged programs, when `research.json` is missing or
       made from other facts (one web-search call per major);
    3. drafts `note.md` with `status: draft`, when the note is missing or made
       from other research, prompt or guide (one text-only call per major).
       A redraft of an approved note goes to `note.next.md`, so the approved
       note stays live until `field_notes.approve` promotes the new one.

  A step whose input hasn't changed is skipped and costs nothing. A reply
  that fails its check is saved next to the notes as `*.rejected.*` and not
  retried.

      mix field_notes.run --keyword-map
      mix field_notes.run "Fire Protection" "Economics"
      mix field_notes.run --keyword-map --dry-run

  Options:

    * `--keyword-map` — add the majors docs/seo/keywords.yml targets
    * `--step research|note` — run one step only (default: both)
    * `--force` — rerun steps whose input hasn't changed
    * `--dry-run` — print what would run, and call nothing
    * `--model` — default `opus`
    * `--budget` — the dollar cap per call (default 1.50 research, 0.25 note)
    * `--max-fields` — refuse to run more majors than this (default 12)
  """
  use Mix.Task

  alias Collegevalue.FieldNotes
  alias Collegevalue.FieldNotes.Claude

  @switches [keyword_map: :boolean, step: :string, force: :boolean, dry_run: :boolean,
             model: :string, budget: :float, max_fields: :integer]

  @impl true
  def run(argv) do
    {opts, names} = OptionParser.parse!(argv, strict: @switches)
    Mix.Task.run("app.start")
    Logger.configure(level: :warning)

    fields = FieldNotes.select_fields(names, opts)
    max = opts[:max_fields] || 12

    cond do
      fields == [] -> Mix.raise("Name the majors, or pass --keyword-map.")
      length(fields) > max -> Mix.raise("#{length(fields)} majors is more than --max-fields #{max}.")
      true -> :ok
    end

    steps = if opts[:step], do: [String.to_existing_atom(opts[:step])], else: [:research, :note]
    spent = Enum.reduce(fields, 0.0, fn name, spent -> spent + field(name, steps, opts) end)
    Mix.shell().info("\nSpent $#{:erlang.float_to_binary(spent * 1.0, decimals: 4)} on #{length(fields)} majors.")
  end

  defp field(name, steps, opts) do
    case FieldNotes.status(name) do
      %{facts: nil} ->
        Mix.shell().info("#{name}: no program reports earnings; skipped")
        0.0

      %{facts: facts} = status ->
        unless opts[:dry_run], do: FieldNotes.write_facts(facts)
        spent = if :research in steps, do: research(status, opts), else: 0.0
        spent + if(:note in steps, do: note(FieldNotes.status(name), opts), else: 0.0)
    end
  end

  defp research(%{name: name, research: state, facts: facts}, opts) do
    cond do
      state == :current and !opts[:force] ->
        Mix.shell().info("#{name}: research current")
        0.0

      opts[:dry_run] ->
        Mix.shell().info("#{name}: would research #{length(facts.flagged)} flagged programs (research #{state})")
        0.0

      true ->
        Mix.shell().info("#{name}: researching #{length(facts.flagged)} flagged programs…")
        prompt = prompt(:research, facts: facts)

        call(name, prompt, ~w(WebSearch WebFetch), opts[:budget] || 1.5, opts, fn text ->
          with {:ok, reply} <- decode_json(text),
               {:ok, research} <- FieldNotes.check_research(reply, facts) do
            FieldNotes.write!(name, "research.json", Jason.encode_to_iodata!(research, pretty: true))
            :ok
          else
            {:error, errors} ->
              FieldNotes.write!(name, "research.rejected.txt", text)
              {:error, errors}
          end
        end)
    end
  end

  defp note(%{name: name, research: research_state, note: state, facts: facts}, opts) do
    cond do
      research_state != :current ->
        Mix.shell().info("#{name}: no current research; note skipped")
        0.0

      not FieldNotes.needs_note?(state) and !opts[:force] ->
        Mix.shell().info("#{name}: note #{state}")
        0.0

      opts[:dry_run] ->
        Mix.shell().info("#{name}: would draft a note (note #{state})")
        0.0

      true ->
        Mix.shell().info("#{name}: drafting the note…")
        research = FieldNotes.read_json(name, "research.json")
        prompt = prompt(:note, facts: facts, research: Map.take(research, ["major", "programs"]))
        model = opts[:model] || "opus"

        call(name, prompt, [], opts[:budget] || 0.25, opts, fn text ->
          body = String.trim(text)

          case FieldNotes.check_note(body, facts) do
            :ok ->
              meta = [field: name, status: "draft", facts_hash: facts.hash, research_hash: research["hash"],
                      prompt_hash: FieldNotes.prompt_hash(:note), model: model,
                      drafted: Date.to_iso8601(Date.utc_today())]

              FieldNotes.write!(name, FieldNotes.draft_file(name), FieldNotes.render_note(meta, body))
              :ok

            {:error, errors} ->
              FieldNotes.write!(name, "note.rejected.md", body)
              {:error, errors}
          end
        end)
    end
  end

  defp call(name, prompt, tools, budget, opts, accept) do
    case Claude.run(prompt, model: opts[:model] || "opus", tools: tools, budget_usd: budget, timeout_ms: 900_000) do
      {:ok, %{text: text, cost_usd: cost}} ->
        case accept.(text) do
          :ok -> Mix.shell().info("#{name}: done ($#{cost})")
          {:error, errors} -> Mix.shell().error("#{name}: rejected ($#{cost}): #{Enum.join(List.wrap(errors), "; ")}")
        end

        cost * 1.0

      {:error, reason} ->
        Mix.shell().error("#{name}: #{reason}")
        0.0
    end
  end

  defp prompt(step, bindings) do
    {template, guide} = FieldNotes.prompt_template(step)

    Enum.reduce(bindings, String.replace(template, "{{guide}}", guide), fn {key, value}, acc ->
      value = value |> strip_hash() |> Jason.encode!(pretty: true)
      String.replace(acc, "{{#{key}}}", value)
    end)
  end

  defp strip_hash(%{} = map), do: Map.delete(map, :hash)
  defp strip_hash(other), do: other

  # Models sometimes wrap JSON in a code fence; take the outermost object.
  defp decode_json(text) do
    with [_ | _] = parts <- Regex.run(~r/\{.*\}/s, text),
         {:ok, json} <- Jason.decode(hd(parts)) do
      {:ok, json}
    else
      _ -> {:error, ["the reply isn't JSON"]}
    end
  end

end
