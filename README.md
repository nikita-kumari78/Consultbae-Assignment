# ConsultBae AI Automation Assignment

## Status
- [x] Task 1 — Merge pipeline (SQLite + MySQL)
- [x] Task 2 — No-code automation (n8n/Make/Zapier)
- [x] Task 3 — Mini audio collection app
- [x] Task 4 — Data issues report
- [x] Task 5 — Stretch (scale-to-5000 note)

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
**Update — verified live on Railway:** hosted this MySQL dump on a live
Railway MySQL instance and imported it via MySQL Workbench — all 57
people confirmed present (`SELECT COUNT(*) FROM people;` → 57). This is
the same live database Task 2's n8n automation connects to.

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

At 57 people, correctness mattered far more than speed — every query in
this repo runs in milliseconds regardless of approach. At 5,000+ people
(and presumably tens of thousands of source rows across the 3 CSVs,
skills, and audio submissions), three parts of this system would need
to change before they broke, not because they're wrong today but
because they were built for correctness-first at small scale.

### 1. Merge pipeline (`scripts/merge.py`)
The union-find over normalized phone/email is algorithmically fine at
any scale (near-linear). The actual bottleneck would be **loading all
3 CSVs fully into memory as Python objects** before merging, which is
what the current script does — fine for ~150 rows, not fine for
50,000+. Fix: stream each CSV row-by-row and build the union-find
incrementally, or push the dedup logic into SQL (`INSERT ... ON
DUPLICATE KEY` style upserts keyed on normalized phone/email) instead
of doing it in application memory. The `match_conflicts` fallback
logic (name+city, unmerged when phone/email actively disagree) stays
exactly the same — it doesn't get more expensive with more people, it
just fires more often in absolute terms.

### 2. Database
Two changes, both already partially in place:
- `idx_phone` and `idx_email` on `people` already exist (see
  `db/consultbae_mysql.sql`) — these are what make the merge/audio-app
  lookups fast; at 5,000 rows they matter far more than they did at 57.
- `skills.skill` has an index too, but the `skills` table itself would
  be the largest table by row count (avg ~5 skills/person × 5,000 =
  25,000 rows) and any query doing `GROUP_CONCAT` across it — like the
  Task 2 automation's `Get Untagged People` query — would benefit from
  a composite index on `(person_id, skill)` rather than relying on the
  single-column index alone.

### 3. Task 2's n8n automation
This is the part that would genuinely need a design change, not just
tuning. The current workflow classifies **one person at a time** via
`Split In Batches` (batch size 1) — deliberate at 57 people, so one bad
LLM response can't corrupt another person's row. At 5,000 people,
that's 5,000 sequential HTTP calls to an LLM API, which is slow (LLM
latency × 5,000, likely hours) and expensive per-call. Two options,
not mutually exclusive:
- **Batch the LLM call, not just the loop**: send 20–50 people's skill
  lists in one prompt, ask for a JSON array of `{person_id, category}`
  back, and validate each entry the same way the current Code node
  validates one. Cuts API calls ~20–50x. Trade-off: one malformed LLM
  response now risks a batch of people instead of one — mitigate by
  keeping the same "fall back to `other`" logic per-entry rather than
  failing the whole batch if one entry is malformed.
- **Run it as a scheduled nightly job** (swap Manual Trigger for
  Schedule Trigger, already noted as an option in `automation/README.md`)
  rather than an on-demand run, since tagging doesn't need to be
  real-time — this turns "5,000 calls block someone waiting" into
  "5,000 calls happen unattended overnight," which is a scaling fix
  that costs nothing to implement.

### What would *not* need to change
The audio app's per-submission phone-match logic (Task 3) is already
O(1) per submission via the indexed phone lookup — 5,000 people doesn't
change that. Same for `match_conflicts` — it's an append-only log, not
a lookup structure, so it scales linearly with no redesign needed.

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
the LLM.

**Update — ran it live:** imported the workflow into n8n, hosted the
MySQL database on Railway, and ran the full workflow end to end. The
MySQL nodes connected and correctly fetched all untagged people. The
LLM HTTP Request node authenticated successfully (confirmed the
request/headers were accepted) — the only remaining failure was the
Anthropic account used for testing not having API credits loaded,
which is a billing issue, not a workflow bug. The auth + request-format
success is what the earlier offline testing was standing in for, and
it held up once actually connected.