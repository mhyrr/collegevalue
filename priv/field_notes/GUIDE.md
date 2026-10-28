# Field notes: editorial guide

The rules for every note on a major's page ("Is a ___ degree worth it?").
Both prompts include this file, so a change here changes the next run of
research and writing. Revise it as reviews teach us more; git keeps the history.

## The job

The page already shows the computed answer: median first-year earnings,
the middle half, median debt and the major's rank. Its tables show, for
each program, months to repay, the four-year cost and years of pay. The
note tells a student
considering this major the one or two things its numbers show that they
wouldn't guess, and that should change how they choose a school or a path.

Value is cost against payoff. The site measures it two ways:

- **Months to repay** (`months_to_repay`): how many months of first-year
  pay the typical student loan takes. It is the debt in a student's own
  terms. Two programs that pay the same are not the same deal when one
  leaves its graduates owing four times as much.
- **The four-year cost** (`four_year_cost`): four years of net price after
  grants, housing and food included, for a family's income bracket, and the
  sticker price beside it. Federal loans cap what a student can borrow, so
  the debt barely moves with price; the family covers the rest
  (`gap_48_75k`) from savings, work, Parent PLUS or private loans. Years of
  pay (`years_of_pay_48_75k`) is that cost over a year of first-year pay.

Cost figures are each college's average for aided first-time students, not
the major's. Quote them as what a family with that income typically pays.
Parents' Parent PLUS loans are a separate debt: mention
`parent_plus_over_24_months` only when a notable share of programs passes
it, and never add it to the student's debt.

Write for the typical student: the one at an ordinary school that admits
most applicants (`by_admission`, band `over_60_percent`), not the one at the
top. When the top is a different job market, say how different, and what
it takes to get in.

## The swap test

Before keeping a sentence, put another major's name in it. If it is still
true, cut it. These are true of nearly every major, and the site explains
them once, on its data and majors pages, not in each note:

- Puerto Rico and other territories pay less in every occupation.
- The most selective schools feed banks, consultancies and big tech, so
  their graduates out-earn everyone's.
- Small cohorts give unreliable figures.
- Pay follows local cost of living.

A note mentions one of these only when this major breaks the pattern
(selectivity barely moves nursing pay) or when it is far stronger here than
anywhere else.

## Where to look

Use the facts first; research supplies the mechanism behind them.

- **How much the school matters.** Compare `by_admission` bands. A wide gap
  (computer science: the schools that admit under a tenth earn far more than
  the open ones) means two markets: say what the typical school's graduates
  earn, what the top jobs are, and how few of them there are. A narrow gap
  (nursing, where a license sets the floor) means the school barely moves
  pay, so cost matters more than name.
- **What it costs.** Compare `by_control` (public, private nonprofit,
  for-profit) and the `by_admission` bands on months to repay, four-year
  cost and years of pay, against the earnings each pays. Selective private
  schools often cost a middle-income family less than open ones; for-profits
  often cost more and pay less. Say which holds for this major.
  `nearby_pair` is the sharpest case: two programs a short drive apart that
  pay about the same, where one leaves graduates owing far more. Use it when
  research finds the two programs comparable (both enroll new students), and
  describe it by place ("two programs 9 miles apart in the Washington area"),
  not by name.
- **Who is in the numbers.** When `largest` pays above the median, holds
  pooled or online programs, or research finds the big programs serve
  working adults (RNs finishing a BSN), say who those graduates are and what
  a student starting from scratch should expect instead.
- **What the major leads to.** A license, a required next degree, the
  usual first job, or the career the major feeds, when it is specific to
  this major: the CPA's extra year, physical therapy school, law school,
  medical school. First-year earnings understate a major whose graduates go
  on to more school.
- **A stepping stone.** Some majors are a means, not the end: at the most
  selective schools, students pick economics, philosophy, history or
  political science on the way to law school, a Ph.D., medicine, or finance,
  consulting and private equity. When research shows the major is used this
  way, say who uses it, what it leads to, and that first-year pay
  understates them. Then say what that means for the typical student, who
  is usually not on that path. This differs from the swap-test pattern:
  the point is why students choose the major, not that selective schools
  pay more.

Skip what the facts and research don't support. A short note with one sharp
point beats a full one with four generic ones.

## Shape

Two paragraphs, two or three sentences each.

1. **The sharpest finding**: the one thing about this major a student
   wouldn't guess.
2. **What to do about it**: the move a student choosing should make, or
   the expectation to set. End on the move.

No sentence that only restates the computed answer above the note.

## Naming schools

Name the schools in an example. A pair of programs that pay alike but cost
differently reads as proof when the student can see which two schools they
are: "Barry University and Miami Dade College, 7 miles apart in Miami, pay
about the same". Use each school's full name exactly as the facts give it
(`college`) on first mention, since the page links that name to the school's
own page; a short form ("Miami Dade") is fine after that.

Also name a school when something specific to it explains its figure:

- it admits only working professionals (SIUC's fire service track);
- its graduates do a different job (Cal Maritime's licensed marine engineers);
- its figure looks wrong, or is pooled with another campus's.

Describe groups by kind: "public universities", "schools that admit under a
tenth of applicants". Never cite one school's outcomes as the major's.

## Numbers and verdicts

- No number that isn't in the facts; the checker rejects the note. Prefer
  words, and use a figure only where it carries the point (months of pay,
  the cost gap, the two markets). The page shows the rest. Quote dollar
  figures as the facts round them ("about $60,000"), and months as written.
- Advise, don't judge. When the facts make the choice clear, say it as
  plain advice: "If you want to be a nurse, get the RN and the bachelor's
  at the lowest cost you can; the license, not the school, sets your pay."
  Advice says what to do. A verdict on the degree ("worth it", "not worth
  it", "a smart choice") is still out: the data covers one year after
  graduating, and the choice is the student's.
- A claim from outside the Scorecard (hiring numbers, licensure rules,
  graduate school rates) must come from the research, with its source.

## Voice

Plain and direct, for a high-school senior and their parents. Active voice,
short sentences, one idea each. Call the major by its `short_name`. No "when
it comes to", no "it's important to note", no "not X, but Y" contrasts, no
dashes as punctuation. Open on the finding, never on a general line about
how the major compares.
