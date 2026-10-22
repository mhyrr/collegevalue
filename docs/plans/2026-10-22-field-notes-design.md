# Field notes: "Is a ___ degree worth it?"

## Goal

Each major's page (`/fields/:name`) answers "Is a ___ degree worth it?" directly,
from College Scorecard data, with a short note that explains what the numbers
hide. The first target is the 8 majors in `docs/seo/keywords.yml`.

## The rule

Code computes, the model interprets. No model output contains a number the
code didn't compute.

## The editorial guide

`priv/field_notes/GUIDE.md` is the single source for how notes read: their
shape (two paragraphs), the questions every note answers (reputation or
major, where, stepping stone), when to name a school, and the voice. Both
prompts include it. Review feedback goes into the guide, not into one
prompt, so it shapes every later run.

## Layers

1. **Facts (code, free).** `Collegevalue.FieldNotes.Facts` computes, per major
   (bachelor's programs only):
   - the program count, the median, 25th and 75th percentile of first-year
     earnings, and the median debt;
   - the median debt-to-earnings ratio, and the major's rank by it among all majors;
   - the **flagged programs**: the top 3 and bottom 3 by earnings, plus the 4
     farthest past 2x or under 0.5x the median (the rest are counted by state
     in `outliers`);
   - `ends`: the states and median admission rate of the 10 best- and
     worst-paying programs, against the major's median admission rate.

   The facts are written to `priv/field_notes/<slug>/facts.json` with a hash.
   The answer section on the page renders from these facts alone, so every
   major gets it, with or without a note.
2. **Research (model, paid).** One call per major. The call gets `facts.json`
   and web search. For each flagged program, it returns a cause from a fixed
   list, one sentence of evidence and a source URL. The output is
   `research.json`, which carries the facts hash it was made from.
3. **Note (model, paid).** One call per major. The call gets the facts, the
   research and the guide, and writes two paragraphs to `note.md`, with
   front matter (`status: draft`).
4. **Review (Greg).** Greg reads the drafts, edits `note.md` and sets
   `status: approved`. Only approved notes render. Git history is the review log.

## Token spend

- `mix field_notes.status` lists what each major needs. Research runs only when
  `research.json` is missing, or was made from other facts, prompt or guide.
  The same holds for a note and its research, prompt and guide. An approved
  note is never overwritten: its redraft goes to `note.next.md`, and the
  approved note stays live until `mix field_notes.approve` promotes it. A Scorecard re-import that
  doesn't change a major's facts costs nothing.
- `mix field_notes.run` calls `claude -p` with only the tools a step needs,
  a dollar cap and a deadline. Adding majors means passing more names; it
  refuses more than `--max-fields` (12) at once.
- Order: the 8 keyword-map majors, then majors by program count.

## Decisions

- Headline figures are medians, so one outlier like SIUC's Fire Protection
  barely moves them, and they never depend on model output. The note explains
  the outliers.
- No "worth it / not worth it" verdict. The data has first-year earnings only,
  which is harsh on majors that pay off later. The section states the facts and
  says what they leave out.
- Notes are files in the repo, not database rows. Production data lives only
  in the Fly volume, and a deploy runs no seeds. Files ship with the release
  and get reviewed in git.

## Causes (fixed list)

`experienced_students`, `online_adult`, `small_cohort`, `selective_school`,
`high_cost_region`, `low_cost_region`, `credential_mismatch`, `data_error`,
`no_clear_cause`.
