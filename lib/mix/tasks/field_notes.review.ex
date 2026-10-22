defmodule Mix.Tasks.FieldNotes.Review do
  @shortdoc "Print each draft note with the facts and research behind it"
  @moduledoc """
  Prints, for each major named (or `--keyword-map`), the computed answer the
  page shows, the research on each flagged program, and the draft note, so a
  reviewer can check the note against its sources. Edit `note.md` by hand,
  then `mix field_notes.approve NAME`.

      mix field_notes.review --keyword-map
  """
  use Mix.Task

  alias Collegevalue.FieldNotes
  import CollegevalueWeb.Views.Helpers, only: [field_question: 1, field_answer: 1, cash: 1]

  @impl true
  def run(argv) do
    {opts, names} = OptionParser.parse!(argv, strict: [keyword_map: :boolean])
    Mix.Task.run("app.start")
    Logger.configure(level: :warning)

    for name <- FieldNotes.select_fields(names, opts), status = FieldNotes.status(name), status.facts do
      research = FieldNotes.read_json(name, "research.json") || %{"programs" => []}
      causes = Map.new(research["programs"], &{&1["unitid"], &1})
      note = FieldNotes.read_note(name)

      Mix.shell().info("""

      ══ #{field_question(name)}  (note #{status.note})
      #{Enum.join(field_answer(status.facts), " ")}

      Flagged programs:
      #{Enum.map_join(status.facts.flagged, "\n", &program(&1, causes))}

      Note (#{FieldNotes.path(name, "note.md")}):
      #{if note, do: note.body, else: "(none)"}
      """)
    end
  end

  defp program(p, causes) do
    found = causes[p.unitid] || %{}

    "  #{p.college} (#{p.state}): #{cash(p.earnings)}, cohort #{p.cohort || "?"}, #{Enum.join(p.reasons, ", ")}\n" <>
      "      #{found["cause"] || "not researched"}: #{found["evidence"]} #{found["source"]}"
  end
end
