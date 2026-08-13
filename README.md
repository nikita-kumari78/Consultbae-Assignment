# ConsultBae AI Automation Assignment

## Status
- [x] Task 1 — Merge pipeline (SQLite)
- [ ] Task 2 — No-code automation (n8n/Make/Zapier)
- [ ] Task 3 — Mini audio collection app
- [x] Task 4 — Data issues report
- [ ] Task 5 — Stretch (scale-to-5000 note)

## Task 1 — Merge

### Design
No single ID is shared across all three sources (Source1 has email+phone,
Source2 has only email, Source3 has only phone), so people are matched via
a union-find over **normalized phone** and **normalized email**, using
Source1 as the bridge between the other two. A name+city fallback match is
used only when it's unambiguous — any case where name+city collide but
phone/email conflict is logged to `match_conflicts` and left unmerged
rather than guessed. Full reasoning and every issue found is in
`reports/data_issues_report.md`.

### Database: MySQL
The pipeline outputs a MySQL-compatible dump: **`db/consultbae_mysql.sql`**
(schema + data, `InnoDB`, proper `FOREIGN KEY` constraints, `JSON` columns
for lineage/audit data). Import it with:
```bash
mysql -u root -p your_database_name < db/consultbae_mysql.sql
```
Note: this sandbox has no network access, so I could not spin up a live
MySQL server to execute the dump against directly here. To validate
correctness without one, I: (1) ran the exact same matching/cleaning logic
against SQLite, which I *could* execute and inspect directly (57 people,
duplicate/alias merges and the one flagged conflict all confirmed correct),
then (2) generated the MySQL dump from those same clustered results, and
(3) statically validated the `.sql` file — statement counts match the
schema (8 `CREATE TABLE`, one per table), quote escaping checked
line-by-line, and sample `INSERT`s spot-checked by hand. Please run the
import yourself and confirm — that's the one part of this deliverable I
couldn't verify end-to-end in this environment.

`db/consultbae.db` (SQLite) is also still included as a working reference —
useful for quickly poking at the data locally without a MySQL server running.

### Schema (mirrors across both SQLite and MySQL)
- `people` — one row per matched real person (canonical name/email/phone/city,
  which sources contributed, match confidence)
- `person_source_records` — one row per original source record, linked to a
  person, full normalized data kept as JSON for audit/lineage
- `skills` — normalized many-to-many skills per person
- `naukri_applications`, `gig_worker_status`, `cbnexus_contacts` — source-specific
  fields, one row per person per source
- `audio_submissions` — Task 3 output lands here
- `match_conflicts` — identity matches the pipeline refused to make automatically

### Run it
```bash
cd scripts
python3 merge.py
```
Reads the 3 CSVs from `data/raw/`, writes `db/consultbae.db`, and writes
`reports/data_issues_log.json` (machine-readable version of the report).

Requires only the Python standard library (`csv`, `sqlite3`, `json`) — no
external dependencies for this step.

## Task 2 — Automation
_TODO_

## Task 3 — Audio app
_TODO_

## Task 4 — Data issues report
See `reports/data_issues_report.md`.

## Task 5 — Stretch: scaling to 5,000 workers
_TODO_

## Stuck log
_Filled in as real snags come up in Tasks 2 and 3 — not written in advance._
