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

  @major %{
    "school_matters" => %{"finding" => "unclear", "evidence" => "Nothing found.", "source" => nil},
    "who_is_counted" => %{"finding" => "new_graduates", "evidence" => "Open to first-year students.", "source" => "https://example.edu/admissions"},
    "leads_to" => %{"finding" => "graduate_school", "evidence" => "Some go on to a master's.", "source" => "https://example.edu/outcomes"},
    "nearby_pair" => %{"finding" => "none", "evidence" => "No nearby pair.", "source" => nil}
  }

  defp reply(facts, overrides \\ %{}) do
    programs =
      for p <- facts.flagged do
        Map.merge(%{"unitid" => p.unitid, "cause" => "no_clear_cause", "evidence" => "Nothing found.", "source" => nil},
                  Map.get(overrides, p.unitid, %{}))
      end

    %{"major" => @major, "programs" => programs}
  end

  @two_paragraphs "Online programs for working firefighters pay the most. Their students already have jobs.\n\n" <>
                    "The lowest figures rest on small classes."

  describe "check_research/2" do
    test "accepts one entry per flagged program and stamps the facts and prompt hashes", %{facts: facts} do
      assert {:ok, research} = FieldNotes.check_research(reply(facts), facts)
      assert research["facts_hash"] == facts.hash
      assert research["prompt_hash"] == FieldNotes.prompt_hash(:research)
      assert research["major"]["leads_to"]["finding"] == "graduate_school"
    end

    test "rejects unknown causes, missing sources and missing programs", %{facts: facts} do
      [first | _] = facts.flagged
      bad = reply(facts, %{first.unitid => %{"cause" => "vibes"}})
      assert {:error, [error]} = FieldNotes.check_research(bad, facts)
      assert error =~ "unknown cause"

      unsourced = reply(facts, %{first.unitid => %{"cause" => "experienced_students"}})
      assert {:error, [error]} = FieldNotes.check_research(unsourced, facts)
      assert error =~ "needs an http(s) source"

      short = Map.update!(reply(facts), "programs", &tl/1)
      assert {:error, [error]} = FieldNotes.check_research(short, facts)
      assert error =~ "no entry for flagged"
    end

    test "wants every major-level question answered, with a source for a finding", %{facts: facts} do
      assert {:error, ["the reply has no major section"]} = FieldNotes.check_research(Map.delete(reply(facts), "major"), facts)

      no_pair = Map.update!(reply(facts), "major", &Map.delete(&1, "nearby_pair"))
      assert {:error, ["major: no nearby_pair answer"]} = FieldNotes.check_research(no_pair, facts)

      unsourced = put_in(reply(facts), ["major", "school_matters"], %{"finding" => "two_markets", "evidence" => "Big tech recruits there."})
      assert {:error, [error]} = FieldNotes.check_research(unsourced, facts)
      assert error =~ "school_matters: finding two_markets needs an http(s) source"
    end
  end

  describe "check_note/2" do
    test "allows the facts' numbers and nothing else", %{facts: facts} do
      ok = "Most programs pay close to the median of $74,000. One pays far more.\n\nThe rest pay less."
      assert FieldNotes.check_note(ok, facts) == :ok

      assert {:error, [error]} = FieldNotes.check_note("Most pay $74,000. Others $91,500.\n\nSome less.", facts)
      assert error =~ "91500"
    end

    test "allows rounded dollar figures, the site's labels and sourced research numbers", %{facts: facts} do
      # The facts hold 74,000; 74,500 and 74,000 are roundings, 48,000 to 75,000 a bracket label.
      ok = "Families earning $48,000 to $75,000 pay most. Graduates earn about $74,000.\n\nSchools that admit under 25 percent cost less over 4 years."
      assert FieldNotes.check_note(ok, facts) == :ok

      research = %{"major" => %{"leads_to" => %{"finding" => "licensure", "evidence" => "Most states require 150 credit hours.", "source" => "https://nasba.org"},
                                "who_is_counted" => %{"finding" => "unclear", "evidence" => "About 2026 adults.", "source" => nil}}}
      note = "A CPA needs 150 credit hours.\n\nThe rest pay less."
      assert {:error, _} = FieldNotes.check_note(note, facts)
      assert FieldNotes.check_note(note, facts, research) == :ok
      # Evidence without a source lends no numbers.
      assert {:error, [error]} = FieldNotes.check_note("About 2026 adults.\n\nThe rest pay less.", facts, research)
      assert error =~ "2026"
    end

    test "wants two paragraphs of one to three sentences", %{facts: facts} do
      assert FieldNotes.check_note(@two_paragraphs, facts) == :ok

      assert {:error, [error]} = FieldNotes.check_note("One paragraph. Only.", facts)
      assert error =~ "1 paragraphs"

      long = "One. Two. Three. Four.\n\nFive."
      assert {:error, [error]} = FieldNotes.check_note(long, facts)
      assert error =~ "paragraphs of 4 and 1 sentences"
    end
  end

  test "sentence_count/1 doesn't end a sentence at an initial or an abbreviation" do
    assert FieldNotes.sentence_count("Graduates of Universidad Ana G. Mendez stay home. Pay is low.") == 2
    assert FieldNotes.sentence_count("It is the poorest U.S. state. Washington University in St. Louis pays well.") == 2
    assert FieldNotes.sentence_count("One. Two! Three?") == 3
  end

  describe "status/1" do
    setup %{facts: facts} do
      {:ok, research} = FieldNotes.check_research(reply(facts), facts)
      meta = [field: "Fire Protection", status: "draft", facts_hash: facts.hash, research_hash: research["hash"],
              prompt_hash: FieldNotes.prompt_hash(:note)]

      %{research: research, meta: meta}
    end

    defp put_note(meta, file \\ "note.md"), do: FieldNotes.write!("Fire Protection", file, FieldNotes.render_note(meta, @two_paragraphs))

    test "walks missing, current, draft, approved and stale", %{research: research, meta: meta} do
      assert %{research: :missing, note: :missing} = FieldNotes.status("Fire Protection")

      FieldNotes.write!("Fire Protection", "research.json", Jason.encode!(research))
      assert %{research: :current, note: :missing} = FieldNotes.status("Fire Protection")

      put_note(meta)
      assert %{note: :draft} = FieldNotes.status("Fire Protection")
      assert FieldNotes.approved_paragraphs("Fire Protection") == []

      put_note(Keyword.put(meta, :status, "approved"))
      assert %{note: :approved} = FieldNotes.status("Fire Protection")
      assert length(FieldNotes.approved_paragraphs("Fire Protection")) == 2

      # New data changes the facts: the research is stale, and the approved
      # note is stale but stays live.
      college = Repo.insert!(%College{name: "Late College", unitid: 999_999, state: "IL"})
      Repo.insert!(%Discipline{name: "Fire Protection", credential_level: 3, earnings_1yr: 30_000,
                               earnings_1yr_count: 30, college_id: college.id})
      assert %{research: :stale, note: :approved_stale} = FieldNotes.status("Fire Protection")
      assert length(FieldNotes.approved_paragraphs("Fire Protection")) == 2
    end

    test "a guide change makes research and notes stale", %{research: research, meta: meta} do
      FieldNotes.write!("Fire Protection", "research.json", Jason.encode!(research))
      put_note(meta)
      assert %{research: :current, note: :draft} = FieldNotes.status("Fire Protection")

      File.write!(Path.join(FieldNotes.root(), "GUIDE.md"), "Name no schools.")
      assert %{research: :stale, note: :stale} = FieldNotes.status("Fire Protection")
    end

    test "a redraft waits beside the approved note, which stays live", %{research: research, meta: meta} do
      FieldNotes.write!("Fire Protection", "research.json", Jason.encode!(research))
      put_note(Keyword.merge(meta, status: "approved", prompt_hash: "older"))
      assert %{note: :approved_stale} = FieldNotes.status("Fire Protection")
      assert FieldNotes.needs_note?(:approved_stale)
      assert FieldNotes.draft_file("Fire Protection") == "note.next.md"

      put_note(meta, "note.next.md")
      assert %{note: :next_draft} = FieldNotes.status("Fire Protection")
      refute FieldNotes.needs_note?(:next_draft)
      assert length(FieldNotes.approved_paragraphs("Fire Protection")) == 2
    end
  end

  test "parse_note/1 reads what render_note/2 writes" do
    text = FieldNotes.render_note([field: "Economics", status: "draft"], "One.\n\nTwo.")
    assert %{meta: %{"field" => "Economics", "status" => "draft"}, body: "One.\n\nTwo."} = FieldNotes.parse_note(text)
  end

  test "keyword_map_fields/1 reads the field pages the keyword map targets, by slug" do
    college = Repo.insert!(%College{name: "Map College", unitid: 888_888, state: "IL"})

    for name <- ["Psychology, General", "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing"] do
      Repo.insert!(%Discipline{name: name, credential_level: 3, college_id: college.id})
    end

    map = Path.join(System.tmp_dir!(), "keywords_#{System.unique_integer([:positive])}.yml")
    File.write!(map, "page: /fields/rank\npage: /fields/psychology\npage: /fields/nursing\npage: /fields/psychology\n")
    on_exit(fn -> File.rm(map) end)

    assert FieldNotes.keyword_map_fields(map) ==
             ["Psychology, General", "Registered Nursing, Nursing Administration, Nursing Research and Clinical Nursing"]

    File.write!(map, "page: /fields/no-such-field\n")
    assert_raise Ecto.NoResultsError, fn -> FieldNotes.keyword_map_fields(map) end
  end
end
