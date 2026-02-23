# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CollegeValue is a Phoenix/Elixir web application that helps students make data-driven college and major decisions using Department of Education College Scorecard data. It uses Phoenix LiveView for interactive components, Ecto/PostgreSQL for data, and Tailwind CSS for styling. Deployed on Fly.io.

## Common Commands

```bash
# Development
mix setup                    # Install deps, create DB, migrate, seed
mix phx.server               # Start dev server at localhost:4000
iex -S mix phx.server        # Start with interactive Elixir shell

# Database
mix ecto.setup               # Create + migrate + seed
mix ecto.reset               # Drop and recreate database
mix ecto.migrate             # Run pending migrations

# Testing
mix test                     # Run full test suite
mix test path/to/test.exs    # Run single test file
mix test path/to/test.exs:42 # Run single test at line

# Assets
mix assets.deploy            # Build production assets (esbuild + tailwind)

# Data files (required for initial setup)
git lfs install && git lfs fetch && git lfs pull
```

## Architecture

### Domain Contexts (lib/collegevalue/)

- **Colleges** (`colleges.ex`) — queries and business logic for college data. Manages `College`, `Discipline`, `Major`, and `Rank` schemas.
- **Fields** (`fields.ex`) — aggregate field/major data across all institutions. Manages `Field` and field `Rank` schemas.
- **Location** (`location.ex`) — geocoding via zipcode lookup. Uses `Zipcode` schema.
- **Pagination** (`pagination.ex`) — offset-based pagination returning page metadata.

### Web Layer (lib/collegevalue_web/)

- **Router** (`router.ex`) — mix of traditional controller routes (`/colleges`, `/colleges/rank`) and LiveView routes (`/fields`, `/search`, `/results/:query`).
- **Controllers** — `CollegeController` and `FieldController` for static pages; `PageController` for home/data pages.
- **LiveView** — `SearchLive.Search` and `SearchLive.Results` for real-time search; `FieldsLive.Index`, `FieldsLive.Show`, `FieldsLive.Matches` for interactive field exploration; `CollegesLive.Matches` and `CollegesLive.Show` for college views.
- **Views/Helpers** — `CollegevalueWeb.Views.Helpers` has formatting utilities (`address/1`, `percent/1`) and rank view definitions.

### Database

The `colleges` table has 85+ columns covering admissions, financials, completion rates, and earnings. The `disciplines` table links majors to colleges with debt/earnings data. The `fields` table is an aggregate roll-up of discipline data across all institutions.

### Key Conventions

- Phoenix context pattern: controllers delegate to context modules, never query the DB directly.
- LiveView components use `handle_event` for user interactions and `handle_params` for URL changes.
- Dev database runs as PostgreSQL user "go"/"go" on localhost.
- Production requires `DATABASE_URL` and `SECRET_KEY_BASE` environment variables.

## Elixir Guidelines

- Elixir lists do not support index-based access via `list[i]` — use `Enum.at/2`, pattern matching, or `List` functions instead.
- Variables are immutable but rebindable — block expressions (`if`, `case`, `cond`) must bind results to a variable: `socket = if connected?(socket), do: assign(socket, :val, val)`.
- Never nest multiple modules in the same file (causes cyclic dependencies).
- Never use map access syntax (`changeset[:field]`) on structs — use `my_struct.field` or `Ecto.Changeset.get_field/2` for changesets.
- Don't use `String.to_atom/1` on user input (memory leak risk).
- Predicate functions end with `?` (e.g., `valid?/1`). Reserve `is_` prefix for guards only.
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure (usually with `timeout: :infinity`).

## Mix Guidelines

- Read docs before using tasks: `mix help task_name`.
- Debug test failures with `mix test test/my_test.exs` or `mix test --failed`.
- `mix deps.clean --all` is almost never needed — avoid unless you have good reason.

## Phoenix Guidelines

- Router `scope` blocks include an optional alias prefixed for all routes — be mindful to avoid duplicate module prefixes.
- Never place controller routes (`get`, `post`, `put`, `delete`) inside `live_session` blocks — `live_session` is exclusively for `live` routes.

## Ecto Guidelines

- Always preload associations in queries when they'll be accessed in templates.
- Remember `import Ecto.Query` in seeds and query modules.
- `Ecto.Schema` fields use `:string` type even for text columns.
- `Ecto.Changeset.validate_number/2` does not support `:allow_nil` — validations only run if a change exists and is non-nil.
- Use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields.
- Fields set programmatically (e.g., foreign keys) must not be listed in `cast` calls.

## Phoenix HTML / HEEx Guidelines

- Templates use `~H` sigils or `.html.heex` files — never `~E`.
- Use `Phoenix.Component.to_form/2` for forms: `assign(socket, form: to_form(...))` and `<.form for={@form}>`.
- Elixir has no `else if`/`elsif` in templates — use `cond` or `case` for multiple conditionals.
- Literal curly braces in templates (e.g., code snippets) require `phx-no-curly-interpolation` on the parent tag.
- HEEx class attrs support lists: `class={["px-2", @flag && "py-5"]}` — always use `[...]` syntax.
- Never use `<% Enum.each %>` for template content — use `<%= for item <- @collection do %>`.
- HEEx comments: `<%!-- comment --%>`.
- Use `{...}` for interpolation within tag attributes and values; use `<%= ... %>` only for block constructs (`if`, `for`, `cond`, `case`).

## LiveView Guidelines

- Never use deprecated `live_redirect`/`live_patch` — use `<.link navigate={href}>`, `<.link patch={href}>`, `push_navigate`, `push_patch`.
- Avoid LiveComponents unless you have a strong specific need.
- When using `phx-hook="MyHook"` with JS-managed DOM, also set `phx-update="ignore"`.
- Never write inline `<script>` tags in HEEx — put JS in `assets/js/`.
- Form inputs with `phx-change` must be inside a `<form>` tag.
- Use LiveView streams for collections to avoid memory issues. Never use deprecated `phx-update="append"` or `phx-update="prepend"`.
- Streams are not enumerable — to filter/refresh, refetch data and re-stream with `reset: true`.

## JS and CSS Guidelines

- Use Tailwind CSS classes for styling.
- Only `app.js` and `app.css` bundles are supported — import vendor deps into these files.
- Never write inline `<script>` tags in templates.
- Never reference external script `src` or link `href` in layouts — import through the asset pipeline.
