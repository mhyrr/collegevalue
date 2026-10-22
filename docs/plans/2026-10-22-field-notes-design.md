# Field notes: "Is a ___ degree worth it?"

## Goal

Each major's page (`/fields/:name`) answers "Is a ___ degree worth it?" directly,
from College Scorecard data, with a short note that explains what the numbers
hide. The first target is the 8 majors in `docs/seo/keywords.yml`.

## The rule

Code computes, the model interprets. No model output contains a number the
code didn't compute.

## Layers

1. **Facts (code, free).** `Collegevalue.FieldNotes.Facts` computes, per major
   (bachelor's programs only):
   - the program count, the median, 25th and 75th percentile of first-year
     earnings, and the median debt;
   - the median debt-to-earnings ratio, and the major's rank by it among all majors;
   - the **flagged programs**: the top 3 and bottom 3 by earnings, and any program
     above 2x or below 0.5x the major's median.

   The facts are written to `priv/field_notes/<slug>/facts.json` with a hash.
   The answer section on the page renders from these facts alone, so every
   major gets it, with or without a note.
2. **Research (model, paid).** One call per major. The call gets `facts.json`
   and web search. For each flagged program, it returns a cause from a fixed
   list, one sentence of evidence and a source URL. The output is
   `research.json`, which carries the facts hash it was made from.
3. **Note (model, paid).** One call per major. The call gets the facts and the
   research, and writes 2 or 3 plain sentences to `note.md`, with front matter
   (`status: draft`). The note then gets a deslopify pass.
4. **Review (Greg).** Greg reads the drafts, edits `note.md` and sets
   `status: approved`. Only approved notes render. Git history is the review log.

## Token spend

- `mix field_notes.status` lists what each major needs. Research runs only when
  `research.json` is missing or its facts hash differs from the current facts.
  The same holds for a note and its research hash. A Scorecard re-import that
  doesn't change a major's facts costs nothing.
- `scripts/field_notes/run.sh` runs one step for one major through
  `claude -p`, with a turn and tool limit. Adding majors means passing more
  names. The script never sweeps all majors.
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
