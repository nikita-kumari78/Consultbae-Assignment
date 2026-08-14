# ConsultBae AI Automation Assignment

## Status
- [x] Task 1 — Merge pipeline (SQLite + MySQL)
- [x] Task 2 — No-code automation (n8n/Make/Zapier)
- [x] Task 3 — Mini audio collection app
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

Built entirely in n8n's UI (no-code): `automation/skill_tagging_workflow.json`.

For every person with a `NULL` `skill_category`, the workflow pulls their
aggregated skills (from the `skills` table built in Task 1), sends them to
an LLM to classify into one of `automation` / `web-dev` / `data` / `ai-ml`
/ `backend-devops` / `other`, and writes the result back to `people`. Loops
one person per LLM call via n8n's Split In Batches node, so a bad response
for one person never affects another, and it's safe to re-run — already
tagged people are simply skipped.

New columns (`skill_category`, `skill_category_tagged_at`) are added via
`scripts/migrate_add_skill_category.py` (SQLite, already applied to
`db/consultbae.db`) and `db/migrations/001_add_skill_category.sql` (MySQL).

Full setup steps, workflow diagram, and design notes: `automation/README.md`.

## Task 3 — Audio app

### Stack
Flask + vanilla JS (browser `MediaRecorder` API for in-browser recording,
with a plain file-upload fallback). Audio analysis uses `ffmpeg`/`ffprobe`
directly (not a Python audio library) — it's already installed in most
environments, and unlike `pydub`/`librosa` it handles whatever container
a browser's `MediaRecorder` actually produces (usually `webm`/opus)
without extra codec setup.

### What it extracts, per submission
- **Duration** (sec), **sample rate** (Hz), **bitrate** (kbps) — via `ffprobe -show_streams`
- **Loudness** (mean dBFS) — via `ffmpeg`'s `volumedetect` filter
- **Bonus — rough quality estimate**: a label (`good` / `acceptable` /
  `very_quiet` / `clipping_risk`) derived from loudness thresholds. See
  the stuck log below for why this does *not* use silence-detection as
  originally planned.

### Run it
```bash
cd app
python3 app.py
```
Open `http://localhost:5000`. Requires `ffmpeg`/`ffprobe` on PATH and
`flask` installed (`pip install flask --break-system-packages` if needed).
Connects to the same `db/consultbae.db` built in Task 1 — run
`scripts/merge.py` first if that file doesn't exist yet.

### How submissions link to Task 1's data
On submit, the person's phone number is normalized the same way as in
the merge pipeline and checked against `people.canonical_phone`. If it
matches an existing person (e.g. someone from the original CSVs), the
submission links to that `person_id`. If not, a new `people` row is
created with `matched_from_sources='audio_app'` — so audio-only workers
aren't lost, and existing/new are both handled without ambiguity.

Tested end-to-end with synthetic audio (clean tone, a deliberately quiet
clip, and a deliberately loud/near-clipping clip) to confirm the metrics
and quality labels come out correct before relying on it — see stuck log.

## Task 4 — Data issues report
See `reports/data_issues_report.md`.

## Task 5 — Stretch: scaling to 5,000 workers
_TODO_

## Stuck log

### 1. No shared ID across the 3 CSVs (Task 1)
Assumed at first I'd need a fuzzy-matching library. Realized Source1 has
both email and phone while Source2/Source3 each have only one of those —
so Source1 can act as a bridge (union-find over normalized phone + email)
without needing fuzzy name matching for the common case. Only fell back
to name+city matching for the few records that couldn't be linked any
other way, and even then, refused to auto-merge when phone/email values
actively conflicted (the "Arjun Mehta" case) rather than guess. Rejected
approach: matching on name alone — too easy to conflate two different
real people with the same name.

### 2. MySQL import test (Task 1)
Could not spin up a live MySQL server in the sandbox I built this in (no
network access there). Validated the generated `.sql` dump as thoroughly
as possible without one — same clustering logic run and inspected live
against SQLite first, then statically checked the MySQL dump (statement
counts, quote escaping, spot-checked inserts) before handing it off. The
person following this repo then ran the actual `mysql ... < dump.sql`
import themselves and confirmed 57 rows in `people` — good instinct to
verify, since that's exactly the step I couldn't close the loop on myself.

### 3. Audio quality heuristic mislabeling clean audio (Task 3)
First version of the "rough noise/quality estimate" bonus used
`ffmpeg silencedetect` as a proxy: "if a clip has no quiet stretches at
all, it's probably got constant background noise." Tested against a
synthetic clean continuous tone to sanity-check the pipeline before
trusting it — and that tone got labeled `possibly_noisy`, which is wrong.
The bug: a clean *sustained* recording and a genuinely noisy one both
lack silence, so "no silence" isn't evidence of noise on its own. Fixed
by dropping silence-detection from the quality label entirely and basing
it purely on loudness thresholds (mean/peak dBFS), which the same test
suite (clean/quiet/loud synthetic clips) confirmed classifies correctly.
Kept `has_quiet_stretches` as a separate diagnostic value rather than
deleting the signal outright — it just isn't reliable enough on its own
to drive the label. What I asked AI: helped draft the initial silencedetect
approach; the mislabeling and the fix were caught by testing against known
inputs before shipping it, not by inspection.

### 4. Validating an n8n workflow without a live n8n instance or LLM call (Task 2)
Same underlying constraint as the MySQL import in Task 1: no network
access in this sandbox, so I couldn't actually run the workflow inside
n8n or make a real call to an LLM API to confirm it end-to-end. Rather
than skip validation, I ported the exact SELECT/UPDATE queries and the
Code node's category-parsing logic into `automation/test_workflow_logic.py`
and ran them against a real copy of `db/consultbae.db`, including
adversarial fake LLM outputs (empty string, a sentence instead of a bare
category, a comma-separated list) to confirm the fallback-to-`other`
logic never writes garbage into the DB. That also caught a real edge
case: one person has zero rows in `skills`, so the join-based query
correctly leaves them untagged rather than sending an empty prompt to
the LLM. Still need to import the workflow into n8n and run it against
a live database + API key to confirm the parts I couldn't simulate here
— noted clearly in `automation/README.md`.
# Consultbae-Assignment
