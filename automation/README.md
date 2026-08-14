# Task 2 — Skill Category Auto-Tagging (n8n)

## What it does
For every person in `people` whose `skill_category` is still `NULL`, the
workflow fetches their aggregated skills (from the `skills` table built in
Task 1), asks an LLM to classify them into one of a fixed set of
categories, and writes the result back — fully no-code, built and run in
n8n's UI, not a Python script.

Categories: `automation`, `web-dev`, `data`, `ai-ml`, `backend-devops`, `other`
(the last one is a deliberate catch-all, not a failure state — see below).

## Files
- `skill_tagging_workflow.json` — the n8n workflow export. Import via
  n8n → Workflows → Import from File.
- `test_workflow_logic.py` — validates the SELECT/UPDATE queries and the
  category-parsing logic against a real copy of the SQLite DB, without
  needing n8n or a live LLM call running (see "How this was tested" below).
- `../scripts/migrate_add_skill_category.py` — adds `skill_category` +
  `skill_category_tagged_at` to `people` (SQLite). Already applied to
  `db/consultbae.db`.
- `../db/migrations/001_add_skill_category.sql` — same migration for the
  MySQL deliverable. `db/consultbae_mysql.sql`'s `CREATE TABLE people` has
  also been updated directly, so a fresh import already includes these
  columns; this `.sql` file is only needed if you're patching a
  database you already imported before this change.

## Workflow structure
```
Manual Trigger
  -> Get Untagged People        (MySQL node, SELECT ... WHERE skill_category IS NULL)
  -> Loop Over People           (Split In Batches, size 1)
       -> Classify Skill Category (LLM)   (HTTP Request -> Anthropic Messages API)
       -> Parse & Validate Category       (Code node)
       -> Update Person Category          (MySQL node, UPDATE ... WHERE person_id = ?)
       -> back to Loop Over People
     (when batch is exhausted) -> Done
```

Batching one person per LLM call (rather than one giant prompt for all 57)
keeps each write scoped to a single row, so a bad LLM response for one
person can't corrupt others, and a failed run can be re-triggered safely —
the `WHERE skill_category IS NULL` filter means already-tagged people are
just skipped on the next run.

## Setup to actually run this
1. Import `skill_tagging_workflow.json` into n8n.
2. Add a **MySQL credential** named to match (or rename in the two MySQL
   nodes) pointing at the database from Task 1's `consultbae_mysql.sql`.
3. Add an **HTTP Header Auth credential** (`x-api-key: <your Anthropic key>`)
   for the "Classify Skill Category (LLM)" node. Any LLM works here —
   swap the URL/body if you'd rather use OpenAI or another provider; the
   parsing node only cares that the response text is one of the allowed
   category slugs.
4. Run manually, or replace the Manual Trigger with a Schedule Trigger for
   this to run automatically (e.g. nightly) as new people get added.

## Why `other` instead of forcing a guess
Not every skill set cleanly fits one bucket (e.g. someone with only
`docker` + `selenium` — devops or automation?). Forcing the LLM into one
of five specific categories every time would mean silently mislabeling
ambiguous people with false confidence. `other` is a legitimate, honest
output, same philosophy as Task 1 logging unmatchable records to
`match_conflicts` instead of guessing.

## How this was tested
This sandbox has no network access (same limitation noted in the main
README for the MySQL import), so I couldn't run n8n live or make a real
Anthropic API call here. What I did instead, same approach as Task 1's
MySQL validation:
- Validated `skill_tagging_workflow.json` is well-formed and every
  connection references a real node (`python3 -c "import json; ..."`,
  see stuck log).
- Ported the SELECT/UPDATE queries and the Code node's parsing logic
  into `test_workflow_logic.py` and ran them against a real copy of
  `db/consultbae.db`: confirms untagged people are fetched correctly,
  garbage/non-compliant LLM output falls back to `other` instead of
  writing bad data, already-tagged people are correctly excluded on a
  second fetch, and values round-trip correctly through the UPDATE.
  Run it yourself: `python3 automation/test_workflow_logic.py`
- One edge case this surfaced: 1 of the 57 people has no rows in
  `skills` at all (a Task 1 record with no skill data in any source).
  The `JOIN`-based query correctly skips them rather than sending an
  empty skill list to the LLM — they'll just stay untagged, which is
  correct, not a bug.

**What I could not verify here**: an actual n8n import and an actual live
LLM call/response. Please import the workflow, wire up real credentials,
and run it against the imported MySQL database to confirm end-to-end —
that's the one part of this deliverable I couldn't close the loop on
myself, same caveat as the MySQL import in Task 1.
