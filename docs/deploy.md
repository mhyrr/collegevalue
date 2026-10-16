# Deploying CollegeValue to Fly

## What runs where

| Piece | Fly app | Notes |
|---|---|---|
| Web | `collegevalue` | 2 machines, `iad`, shared-cpu-1x / 512 MB, auto-stop. Serves collegevalue.co and www (Fly certs) and collegevalue.fly.dev. |
| Database | `collegevalue-db` | **Unmanaged** Fly Postgres (postgres-flex 17.2), one primary, one 1 GB encrypted volume `pg_data`. Fly does not support or recover it; we do. |

Secrets on `collegevalue`: `DATABASE_URL`, `SECRET_KEY_BASE`. `PHX_HOST` and
the rest are in `fly.toml`. Canonical links use `config :collegevalue,
:canonical_url` in `config/prod.exs` (`https://collegevalue.co`), not `PHX_HOST`.

## What a deploy does to the database

`fly deploy` builds the Dockerfile from the **local working directory** (not
git), then runs `release_command = "/app/bin/migrate"` once, in a temporary
machine, before the new machines start. `migrate` calls
`Collegevalue.Release.migrate/0`, which runs pending Ecto migrations and
nothing else. No seeds and no data import run on deploy. The data
(colleges, disciplines, zips) was loaded once and lives only in the volume.

So a deploy changes the database only when it ships a migration that prod
hasn't run. If the release command fails, Fly does not roll out the new
image; the old machines keep serving.

Some migrations load or reshape data (`add_fields_data`, `add_inst_data`).
Treat any new migration as a data change: snapshot first, and read it for
`DROP`, `DELETE`, `UPDATE` or column type changes.

## Backups

- The `pg_data` volume has scheduled daily snapshots, kept 5 days.
- That is the only backup by default. It lives with Fly, in the same region.
  Take a `pg_dump` before any risky change.

```sh
fly volumes snapshots list vol_vgjq8j6loq7zow0v -a collegevalue-db
fly volumes snapshots create vol_vgjq8j6loq7zow0v -a collegevalue-db   # on-demand

# Off-Fly dump: proxy the DB, then dump with the credentials from DATABASE_URL.
fly proxy 15432:5432 -a collegevalue-db
pg_dump -Fc -h localhost -p 15432 -U <user> -d <db> -f collegevalue-$(date +%F).dump
```

Restore from a snapshot means a new volume from the snapshot and a new
Postgres machine on it: `fly volumes create pg_data --snapshot-id <id> -a collegevalue-db`.
Practice it on a scratch app before you need it.

## Runbook

### Before

1. On the commit you mean to ship, with a clean tree: `git status` (the
   build takes the working directory, untracked files included).
2. `mix test`.
3. Compare migrations. Prod:
   ```sh
   fly ssh console -a collegevalue -C '/app/bin/collegevalue rpc "Ecto.Migrator.migrations(Collegevalue.Repo) |> Enum.each(&IO.inspect/1)"'
   ```
   Every row should be `:up`; `ls priv/repo/migrations` should hold no file
   beyond them. A new one means: snapshot, and read it first.
4. Row-count baseline (fly's `-C` strips double quotes; base64 the Elixir):
   ```sh
   EX='Collegevalue.Repo.query!("select (select count(*) from colleges), (select count(*) from disciplines), (select count(*) from fields), (select count(*) from zips)").rows |> IO.inspect()'
   fly ssh console -a collegevalue -C "/app/bin/collegevalue rpc Code.eval_string(Base.decode64!(~s($(printf %s "$EX" | base64))))"
   ```
   Baseline on 2026-10-16: `[[7852, 229076, 393, 41483]]`.
5. Note the current image for rollback: `fly status -a collegevalue` (the `Image` line).

### Deploy

```sh
fly deploy -a collegevalue
```

### After

1. `fly status -a collegevalue`: both machines `started` on the new version.
2. Re-run the row-count check; it must match the baseline.
3. Smoke: `https://collegevalue.co/`, a college page, a field page,
   `/sitemap.xml`, `/robots.txt`.
4. `fly logs -a collegevalue` for crashes.

### Roll back

```sh
fly releases -a collegevalue --image          # find the previous image
fly deploy -a collegevalue --image <previous image>
```

Rolling back the code does not roll back a migration. For that, run
`Collegevalue.Release.rollback/2` (`/app/bin/collegevalue eval
'Collegevalue.Release.rollback(Collegevalue.Repo, <version>)'`), or restore
from a snapshot.

## Known follow-ups

- `collegevalue-db` runs postgres-flex 17.2; 17.7 is available (`fly image update -a collegevalue-db`).
  Do it apart from an app deploy, after a fresh snapshot.
- The volume is 1 GB at 23% used (201 MB, 2026-10-16).
