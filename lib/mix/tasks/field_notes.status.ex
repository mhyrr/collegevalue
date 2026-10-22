defmodule Mix.Tasks.FieldNotes.Status do
  @shortdoc "What each major's field notes need, and what a run would cost in calls"
  @moduledoc """
  For each major named (or `--keyword-map`), shows the facts hash and the
  state of its research and note. Nothing is called and nothing is written.

      mix field_notes.status --keyword-map
  """
  use Mix.Task

  alias Collegevalue.FieldNotes

  @impl true
  def run(argv) do
    {opts, names} = OptionParser.parse!(argv, strict: [keyword_map: :boolean])
    Mix.Task.run("app.start")
    Logger.configure(level: :warning)

    statuses = names |> FieldNotes.select_fields(opts) |> Enum.map(&FieldNotes.status/1)
    if statuses == [], do: Mix.raise("Name the majors, or pass --keyword-map.")

    for s <- statuses do
      hash = if s.facts, do: s.facts.hash, else: "-"
      flagged = if s.facts, do: length(s.facts.flagged), else: 0

      Mix.shell().info(
        String.pad_trailing(s.name, 60) <>
          "  facts #{hash}  #{flagged} flagged  research #{s.research}  note #{s.note}"
      )
    end

    research_calls = Enum.count(statuses, &(&1.research in [:missing, :stale]))
    note_calls = Enum.count(statuses, &(&1.note in [:missing, :stale]))
    Mix.shell().info("\nA run would make #{research_calls} research and #{note_calls} note calls.")
  end
end
