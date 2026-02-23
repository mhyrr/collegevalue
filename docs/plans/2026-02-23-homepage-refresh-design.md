# Homepage Refresh Design

## Summary

Polish the College Value homepage: restructure the tools/links section into a responsive card grid, edit the copy for more professional tone while keeping the direct voice, remove the Blog nav link, and tighten the email capture section header.

Google Analytics and Beehiiv email capture are already in place — no changes needed there.

## Changes

### 1. Tools Section — Card Grid

Replace the flat `<ul>` list with a two-tier responsive card grid.

**Top tier (personalized tools):** 3 cards — Colleges For You, Majors For You, ROI Calculator.
- Desktop: `grid grid-cols-3 gap-6`
- Mobile: `grid-cols-1` (stacked)
- Styling: white bg, `border border-gray-200 rounded-lg`, darkgreen top accent (`border-t-4 border-t-darkgreen`), hover shadow transition, padding
- Each card: title (darkgreen, bold), short tagline (2-3 lines max), entire card is a link

**Bottom tier (rankings):** 2 cards — College Rankings, Major Rankings.
- Desktop: `grid grid-cols-2 gap-6`
- Mobile: `grid-cols-1` (stacked)
- Styling: same as top tier but without the accent border, slightly more compact
- Introduced by a one-line sentence: "Just want to see the top schools and majors regardless of match?"

### 2. Copy Polish

Sentence-level edits throughout "The Choice" section. Key changes:

- "There's a lot of questions" → "There are a lot of questions" (grammar)
- Tighten the list of college issues — focus on cost as the climax, trim the enumeration
- "need to do a better job at" → "should do a better job of"
- Remove redundant "And" sentence starters
- Fix "Wilmington Univeristy" typo
- "We think they all suck" → "We think they're built backwards" (same energy, more authority)
- Remove "an MVP" (undersells the site)
- Tighten throughout without changing structure or examples

### 3. Nav Cleanup

Remove the "Blog!" link from both `#mobileMenu` and `#normalMenu` in `root.html.heex`.

### 4. Email Capture Header

"Want Some More? Sign Up!" → "Stay In The Loop"

### Files Changed

1. `lib/collegevalue_web/templates/page/home.html.heex` — card grid, copy polish, email header
2. `lib/collegevalue_web/templates/layout/root.html.heex` — remove Blog links

### Mobile Responsiveness

All card grids use Tailwind responsive prefixes (`md:grid-cols-3`, `md:grid-cols-2`) to stack single-column on mobile. Cards get full width on small screens with consistent padding.
