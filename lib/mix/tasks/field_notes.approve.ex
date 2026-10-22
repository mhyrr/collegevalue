defmodule Mix.Tasks.FieldNotes.Approve do
  @shortdoc "Approve (or --reject) a major's draft note so the page shows it"
  @moduledoc """
  Sets `status: approved` in each named major's `note.md`, after checking the
  note, edits included, against the current facts. When a redraft waits in
  `note.next.md`, approving promotes it over the live note. `--reject` sets
  `status: rejected`, which keeps the note off the page and stops the runner
  redrafting it until its inputs change.

      mix field_notes.approve "Psychology, General"
      mix field_notes.approve --reject "Economics"
  """
  use Mix.Task

  alias Collegevalue.FieldNotes

  @impl true
  def run(argv) do
    {opts, names} = OptionParser.parse!(argv, strict: [reject: :boolean])
    Mix.Task.run("app.start")
    Logger.configure(level: :warning)

    for name <- names do
      status = FieldNotes.status(name)
      next = FieldNotes.read_note(name, "note.next.md")
      note = next || FieldNotes.read_note(name) || Mix.raise("#{name}: no note.md")

      cond do
        status.note in [:stale, :approved_stale] ->
          Mix.raise("#{name}: the note was made from older facts or research; rerun field_notes.run")

        opts[:reject] ->
          save(name, note, "rejected")

        true ->
          case FieldNotes.check_note(note.body, status.facts) do
            :ok -> save(name, note, "approved")
            {:error, errors} -> Mix.raise("#{name}: #{Enum.join(errors, "; ")}")
          end
      end
    end
  end

  # Approving a redraft (note.next.md) promotes it over the live note.
  defp save(name, note, state) do
    meta = note.meta |> Map.put("status", state) |> Enum.sort_by(&elem(&1, 0))
    FieldNotes.write!(name, "note.md", FieldNotes.render_note(meta, note.body))
    File.rm(FieldNotes.path(name, "note.next.md"))
    Mix.shell().info("#{name}: #{state}")
  end
end
