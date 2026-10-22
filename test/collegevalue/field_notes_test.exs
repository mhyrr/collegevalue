defmodule Collegevalue.FieldNotesTest do
  use Collegevalue.DataCase

  alias Collegevalue.FieldNotes
  alias Collegevalue.Colleges.{College, Discipline}

  setup do
    root = Path.join(System.tmp_dir!(), "field_notes_#{System.unique_integer([:positive])}")
    Application.put_env(:collegevalue, :field_notes_root, root)

    on_exit(fn ->
      Application.delete_env(:collegevalue, :field_notes_root)
      File.rm_rf!(root)
    end)

    # SIUC-shaped: one program far above the rest.
    for earnings <- [70_000, 72_000, 74_000, 76_000, 160_000] do
      n = System.unique_integer([:positive])
      college = Repo.insert!(%College{name: "College #{n}", unitid: n, state: "IL"})
      Repo.insert!(%Discipline{name: "Fire Protection", credential_level: 3, earnings_1yr: earnings,
                               earnings_1yr_count: 30, pp_debt_median: 20_000, college_id: college.id})
    end

    %{facts: Collegevalue.FieldNotes.Facts.for_field("Fire Protection")}
  end

  defp reply(facts, overrides \\ %{}) do
    programs =
      for p <- facts.flagged do
        Map.merge(%{"unitid" => p.unitid, "cause" => "no_clear_cause", "evidence" => "Nothing found.", "source" => nil},
                  Map.get(overrides, p.unitid, %{}))
      end

    %{"programs" => programs}
  end

  describe "check_research/2" do
    test "accepts one entry per flagged program and stamps the facts hash", %{facts: facts} do
      assert {:ok, research} = FieldNotes.check_research(reply(facts), facts)
      assert research["facts_hash"] == facts.hash
      assert is_binary(research["hash"])
    end

    test "rejects unknown causes, missing sources and missing programs", %{facts: facts} do
      [first | _] = facts.flagged
      bad = reply(facts, %{first.unitid => %{"cause" => "vibes"}})
      assert {:error, [error]} = FieldNotes.check_research(bad, facts)
      assert error =~ "unknown cause"

      unsourced = reply(facts, %{first.unitid => %{"cause" => "experienced_students"}})
      assert {:error, [error]} = FieldNotes.check_research(unsourced, facts)
      assert error =~ "needs an http(s) source"

      short = %{"programs" => tl(reply(facts)["programs"])}
      assert {:error, [error]} = FieldNotes.check_research(short, facts)
      assert error =~ "no entry for flagged"
    end
  end

  describe "check_note/2" do
    test "allows the facts' numbers and nothing else", %{facts: facts} do
      ok = "Most programs pay close to the median of $74,000. One pays far more because it admits working professionals."
      assert FieldNotes.check_note(ok, facts) == :ok

      assert {:error, [error]} = FieldNotes.check_note("Most pay $74,000. Graduates average $91,500 by year 5.", facts)
      assert error =~ "91500"
    end

    test "wants two to four sentences", %{facts: facts} do
      assert {:error, [error]} = FieldNotes.check_note("Just one sentence.", facts)
      assert error =~ "1 sentences"
    end
  end

  test "sentence_count/1 doesn't end a sentence at an initial or an abbreviation" do
    assert FieldNotes.sentence_count("Graduates of Universidad Ana G. Mendez stay home. Pay is low.") == 2
    assert FieldNotes.sentence_count("It is the poorest U.S. state. Washington University in St. Louis pays well.") == 2
    assert FieldNotes.sentence_count("One. Two! Three?") == 3
  end

  describe "status/1" do
    test "walks missing, current, stale and approved", %{facts: facts} do
      assert %{research: :missing, note: :missing} = FieldNotes.status("Fire Protection")

      {:ok, research} = FieldNotes.check_research(reply(facts), facts)
      FieldNotes.write!("Fire Protection", "research.json", Jason.encode!(research))
      assert %{research: :current, note: :missing} = FieldNotes.status("Fire Protection")

      body = "The school matters less here than in most majors. One program pays far more."
      meta = [field: "Fire Protection", status: "draft", facts_hash: facts.hash, research_hash: research["hash"]]
      FieldNotes.write!("Fire Protection", "note.md", FieldNotes.render_note(meta, body))
      assert %{note: :draft} = FieldNotes.status("Fire Protection")
      assert FieldNotes.approved_paragraphs("Fire Protection") == []

      FieldNotes.write!("Fire Protection", "note.md", FieldNotes.render_note(Keyword.put(meta, :status, "approved"), body))
      assert FieldNotes.approved_paragraphs("Fire Protection") == [body]

      # New data changes the facts, so the research and the note behind them are stale.
      college = Repo.insert!(%College{name: "Late College", unitid: 999_999, state: "IL"})
      Repo.insert!(%Discipline{name: "Fire Protection", credential_level: 3, earnings_1yr: 30_000,
                               earnings_1yr_count: 30, college_id: college.id})
      assert %{research: :stale, note: :stale} = FieldNotes.status("Fire Protection")
    end
  end

  test "parse_note/1 reads what render_note/2 writes" do
    text = FieldNotes.render_note([field: "Economics", status: "draft"], "One.\n\nTwo.")
    assert %{meta: %{"field" => "Economics", "status" => "draft"}, body: "One.\n\nTwo."} = FieldNotes.parse_note(text)
  end

  test "keyword_map_fields/0 reads the field pages the keyword map targets" do
    fields = FieldNotes.keyword_map_fields()
    assert "Psychology, General" in fields
    refute "rank" in fields
  end
end
