# Homepage Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish the College Value homepage with a card-grid tools section, tightened copy, nav cleanup, and domain/email updates.

**Architecture:** Two files change — the homepage template and root layout. The tools section becomes a responsive Tailwind CSS card grid. Copy edits are in-place. No backend changes.

**Tech Stack:** Phoenix templates (HEEx), Tailwind CSS

**CRITICAL — Inverted Tailwind breakpoints:** This project uses `max-width` breakpoints (opposite of default Tailwind). `md:` = max-width 767px (mobile). No prefix = all screens including desktop. So desktop styles have NO prefix and mobile overrides use `md:`.

---

### Task 1: Replace tools section with card grid

**Files:**
- Modify: `lib/collegevalue_web/templates/page/home.html.heex:8-30`

**Step 1: Replace the tools `<ul>` lists with card grid**

Replace lines 8–30 (the `<article>` opening through the closing `</p>` of the second `<ul>`) with:

```heex
    <article class="content-center">

      <p class="text-lg pb-4">
          <b>They say college is a credential. Fine, let's treat it like one.</b> What do you get for your money? Can we measure it?
          <br/>
          Start here:
      </p>

      <div class="grid grid-cols-3 md:grid-cols-1 gap-6 pb-6">
        <a href="/colleges/you" class="block no-underline border border-gray-200 rounded-lg border-t-4 border-t-darkgreen p-6 hover:shadow-lg transition-shadow bg-white">
          <h3 class="text-darkgreen text-xl font-display font-bold pb-2">Colleges For You</h3>
          <p class="text-gray-600 text-sm">Find colleges where grads earn more and owe less. Filter by location and SAT score.</p>
        </a>

        <a href="/fields/you" class="block no-underline border border-gray-200 rounded-lg border-t-4 border-t-darkgreen p-6 hover:shadow-lg transition-shadow bg-white">
          <h3 class="text-darkgreen text-xl font-display font-bold pb-2">Majors For You</h3>
          <p class="text-gray-600 text-sm">Compare the same major across different schools. See which ones deliver the best outcomes for the least debt.</p>
        </a>

        <a href="/calculator" class="block no-underline border border-gray-200 rounded-lg border-t-4 border-t-darkgreen p-6 hover:shadow-lg transition-shadow bg-white">
          <h3 class="text-darkgreen text-xl font-display font-bold pb-2">ROI Calculator</h3>
          <p class="text-gray-600 text-sm">Is a specific college + major worth it for you? Enter your details for personalized ROI projections.</p>
        </a>
      </div>

      <p class="pb-4">Just want to see the <b>top schools and majors</b> regardless of location and match?</p>

      <div class="grid grid-cols-2 md:grid-cols-1 gap-6 pb-6">
        <a href="/colleges/rank" class="block no-underline border border-gray-200 rounded-lg p-5 hover:shadow-lg transition-shadow bg-white">
          <h3 class="text-darkgreen text-lg font-display font-bold pb-1">College Rankings</h3>
          <p class="text-gray-600 text-sm">The best and worst colleges based on earnings and debt.</p>
        </a>

        <a href="/fields/rank" class="block no-underline border border-gray-200 rounded-lg p-5 hover:shadow-lg transition-shadow bg-white">
          <h3 class="text-darkgreen text-lg font-display font-bold pb-1">Major Rankings</h3>
          <p class="text-gray-600 text-sm">The best and worst college majors based on earnings and debt.</p>
        </a>
      </div>
```

**Step 2: Verify visually**

Run: `mix phx.server`
Check: Desktop shows 3-column top row, 2-column bottom row. Resize to mobile width — all cards stack single-column.

**Step 3: Commit**

```bash
git add lib/collegevalue_web/templates/page/home.html.heex
git commit -m "feat: replace tools list with responsive card grid"
```

---

### Task 2: Polish the copy in "The Choice" section

**Files:**
- Modify: `lib/collegevalue_web/templates/page/home.html.heex:32-72` (approx, after Task 1 renumbers lines)

**Step 1: Apply copy edits**

Replace the entire "The Choice" section (from `<h2>` through the closing `</p>` before the email section) with:

```heex
      <h2 class="text-darkgreen text-2xl font-display pt-8 pb-2">The Choice</h2>
        <p>
          Should you go to college? What should you study? How much will it cost?
        </p>
        <br/>
        <p>
          There are a lot of questions around college right now — the growing number of administrators compared to faculty,
          the country-club amenities on campus, the shifting priorities in student life, and above all,
          the <b>sheer ballooning cost.</b>
        </p>
        <br/>
        <p>
          Most importantly, there's a question of value. When so many students are going into tremendous debt for the hope
          of a better job — and consequently, more financial freedom — it's perfectly reasonable to ask: is it worth it?
        </p>
        <br/>

        <p>
          College in the modern world is a <a class="no-underline text-green" href="https://www.kanonical.io/education-backwards/">cost/benefit analysis</a>.
          We spend money to be educated for a purpose, and we should do a better job of considering the outcomes.
          Different majors and colleges vary enormously in both cost and estimated payoff — and that's why this place exists.
          The Department of Education publishes this data, but it's hard to find and harder to parse. Some of it is missing, so keep that in mind too.
          <%= link "There's more about the data here", to: "/data", class: "no-underline text-green" %>.
        </p>
        <br/>
        <p>
          The original thesis behind building this was that considering either colleges OR majors isn't enough.
          For instance, a <a class="no-underline text-green" href="/fields/Registered%20Nursing%2C%20Nursing%20Administration%2C%20Nursing%20Research%20and%20Clinical%20Nursing?order=desc&sort_by=earnings">nursing degree</a>
          from <a class="no-underline text-green" href="/colleges/131113/Wilmington%20University">Wilmington University</a> is not the same as one from
          <a class="no-underline text-green" href="/colleges/130226/Quinnipiac%20University">Quinnipiac University</a>. A graduate from either can expect to earn about $72,000 a year,
          but the Quinnipiac grad will have $77,000 in debt and the Wilmington U. grad will have less than $10k.
        </p>
        <br/>
        <p>
           There's plenty to explore across different
           <a class="no-underline text-green" href="/fields/rank">fields</a> and <a class="no-underline text-green" href="/colleges/rank">colleges</a>.
           Our goal is to help you figure out what it really means to get the most out of college, knowing that every dollar matters.
           College isn't one-size-fits-all — every student's needs and goals are different. We want to get you the data you need.
           There are plenty of other college review sites. <b>We think they're built backwards</b> — designed to serve college admissions offices, not prospective students.
           This is an experiment, built on the idea of measuring schools by their outcomes. Let us know what you think!
        </p>
```

Key changes:
- "What do you study?" → "What should you study?" (parallel structure)
- "There's a lot" → "There are a lot" (grammar)
- Trimmed the issues enumeration, focused on cost
- "need to do a better job at" → "should do a better job of"
- Fixed "Wilmington Univeristy" typo
- "We think they all suck" → "We think they're built backwards"
- Removed "an MVP"

**Step 2: Commit**

```bash
git add lib/collegevalue_web/templates/page/home.html.heex
git commit -m "copy: polish The Choice section for professional tone"
```

---

### Task 3: Update email section header and contact info

**Files:**
- Modify: `lib/collegevalue_web/templates/page/home.html.heex` (email/ideas sections near bottom)

**Step 1: Update the email header and contact section**

Change "Want Some More? Sign Up!" to "Stay In The Loop".

Change the "Have Ideas?" section: update email from `troy@collegevalue.dev` to `greg@collegevalue.co` and tighten the copy:

```heex
    <h2 class="text-darkgreen text-2xl font-display py-8">Stay In The Loop</h2>
    <article class="items-center">
      <iframe src="https://embeds.beehiiv.com/8f16ef98-f0d5-4ba4-aec1-05aea7685f06" data-test-id="beehiiv-embed" width="100%" height="320" frameborder="0" scrolling="no" style="border-radius: 4px; margin: 0; background-color: transparent;"></iframe>
    </article>

    <h2 class="text-darkgreen text-2xl font-display py-8">Have Ideas?</h2>
    <article class="items-center">
      <p>This is going to evolve a lot over time. We're looking for more data to incorporate and more stories to tell! If you have ideas or things you'd like to see, <a class="no-underline text-green" href="mailto:greg@collegevalue.co">drop a line!</a></p>
    </article>
```

**Step 2: Commit**

```bash
git add lib/collegevalue_web/templates/page/home.html.heex
git commit -m "copy: update email section header and contact info"
```

---

### Task 4: Remove Blog links from nav

**Files:**
- Modify: `lib/collegevalue_web/templates/layout/root.html.heex`

**Step 1: Remove Blog link from mobile menu**

Delete lines 81-83 (the `<div>` containing the Beehiiv blog link in `#mobileMenu`):

```heex
                  <div class="md:block md:mt-2 inline-block mt-0 text-teal-200 hover:text-white mr-4">
                    <a href="https://collegevalue.beehiiv.com/" class="no-underline text-plainlight">Blog!</a>
                  </div>
```

**Step 2: Remove Blog link from desktop menu**

Delete lines 124-126 (the `<div>` containing the Beehiiv subscribe link in `#normalMenu`):

```heex
                    <div class="md:block md:mt-2 inline-block mt-0 text-teal-200 hover:text-white mr-4">
                      <a href="https://collegevalue.beehiiv.com/subscribe" class="no-underline text-plainlight">Blog!</a>
                    </div>
```

**Step 3: Commit**

```bash
git add lib/collegevalue_web/templates/layout/root.html.heex
git commit -m "nav: remove Blog links from mobile and desktop menus"
```

---

### Task 5: Update domain reference in runtime config

**Files:**
- Modify: `config/runtime.exs:62`

**Step 1: Update check_origin**

The `check_origin` list includes `collegevalue.dev`. Keep it for backwards compat since both domains may be active, but verify. Current line:

```elixir
    check_origin: ["//*.fly.dev", "//*.collegevalue.dev", "//*.collegevalue.co"],
```

This already includes `.co`. No change needed unless the `.dev` domain is fully retired. Leave as-is.

**Step 2: Verify no other domain references**

Already confirmed — no other `collegevalue.dev` references exist outside the two already addressed (home template handled in Task 3, runtime config already has both).

---

### Task 6: Visual verification

**Step 1: Start dev server and check**

Run: `mix phx.server`

Verify at `localhost:4000`:
- [ ] Card grid: 3 top cards in a row on desktop, stacked on mobile
- [ ] Card grid: 2 bottom cards in a row on desktop, stacked on mobile
- [ ] Cards have darkgreen top accent, hover shadow effect
- [ ] Copy reads cleanly with all edits applied
- [ ] "Wilmington University" spelled correctly (no typo)
- [ ] Email link goes to `mailto:greg@collegevalue.co`
- [ ] Blog link is gone from nav (both mobile and desktop)
- [ ] "Stay In The Loop" header above Beehiiv embed
- [ ] Newsletter embed still loads and works

**Step 2: Commit any fixes if needed**
