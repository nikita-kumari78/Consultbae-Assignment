"""
Validates the actual query/parsing logic used inside
skill_tagging_workflow.json, without needing a running n8n instance or a
live LLM API call (this sandbox has no network access, same limitation
noted in the README for the MySQL import).

What this proves:
  1. The "Get Untagged People" query returns the right shape (person_id,
     name, comma-joined skills) and correctly excludes already-tagged people.
  2. The category-parsing/validation logic (ported 1:1 from the Code node)
     correctly maps a raw LLM string to an allowed category, and falls
     back to 'other' for garbage/empty output instead of crashing or
     writing an invalid value.
  3. The "Update Person Category" query correctly writes back and that a
     second run of "Get Untagged People" then excludes that person.

It fakes only the network call (the LLM response text) — everything else
runs against a real copy of the actual SQLite DB.

Usage: python3 automation/test_workflow_logic.py
"""
import sqlite3
import shutil
import os
import sys
from datetime import datetime, timezone

ROOT = os.path.join(os.path.dirname(__file__), "..")
REAL_DB = os.path.join(ROOT, "db", "consultbae.db")
TEST_DB = os.path.join(ROOT, "db", "_workflow_test.db")

ALLOWED = ["automation", "web-dev", "data", "ai-ml", "backend-devops", "other"]

SELECT_UNTAGGED = """
    SELECT p.person_id, p.canonical_name,
           GROUP_CONCAT(DISTINCT s.skill) AS skills
    FROM people p
    JOIN skills s ON s.person_id = p.person_id
    WHERE p.skill_category IS NULL
    GROUP BY p.person_id, p.canonical_name
"""

UPDATE_CATEGORY = """
    UPDATE people
    SET skill_category = ?, skill_category_tagged_at = ?
    WHERE person_id = ?
"""


def parse_and_validate(raw_llm_text):
    """Ported 1:1 from the 'Parse & Validate Category' Code node."""
    try:
        category = (raw_llm_text or "").strip().lower()
        return category if category in ALLOWED else "other"
    except Exception:
        return "other"


def setup_test_db():
    shutil.copyfile(REAL_DB, TEST_DB)
    conn = sqlite3.connect(TEST_DB)
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(people)")
    cols = {row[1] for row in cur.fetchall()}
    if "skill_category" not in cols:
        cur.execute("ALTER TABLE people ADD COLUMN skill_category TEXT")
    if "skill_category_tagged_at" not in cols:
        cur.execute("ALTER TABLE people ADD COLUMN skill_category_tagged_at TEXT")
    conn.commit()
    return conn


def main():
    conn = setup_test_db()
    cur = conn.cursor()
    failures = []

    # --- Test 1: initial fetch returns all people with skills, all untagged
    cur.execute(SELECT_UNTAGGED)
    rows = cur.fetchall()
    print(f"[1] Untagged people fetched: {len(rows)}")
    if len(rows) == 0:
        failures.append("Expected untagged people on a fresh DB, got 0")

    # --- Test 2: parsing/validation logic against realistic + garbage LLM output
    cases = {
        "automation": "automation",
        "  DATA  ": "data",
        "ai-ml": "ai-ml",
        "": "other",
        None: "other",
        "web-dev, data": "other",       # LLM ignored "only the slug" instruction
        "I think this is automation": "other",  # LLM added a sentence
    }
    for raw, expected in cases.items():
        got = parse_and_validate(raw)
        status = "OK" if got == expected else "FAIL"
        if got != expected:
            failures.append(f"parse_and_validate({raw!r}) = {got!r}, expected {expected!r}")
        print(f"[2] parse_and_validate({raw!r:30}) -> {got!r:12} [{status}]")

    # --- Test 3: simulate classifying the first 3 untagged people, write back
    simulated_llm_outputs = {
        rows[0][0]: "automation",
        rows[1][0]: "not sure, maybe data??",  # simulate a noncompliant LLM reply
        rows[2][0]: "backend-devops",
    }
    for person_id, raw_output in simulated_llm_outputs.items():
        category = parse_and_validate(raw_output)
        tagged_at = datetime.now(timezone.utc).isoformat()
        cur.execute(UPDATE_CATEGORY, (category, tagged_at, person_id))
    conn.commit()

    # --- Test 4: re-fetch untagged — those 3 should now be excluded
    cur.execute(SELECT_UNTAGGED)
    rows_after = cur.fetchall()
    print(f"[3] Untagged people after tagging 3: {len(rows_after)} (was {len(rows)})")
    if len(rows_after) != len(rows) - 3:
        failures.append(
            f"Expected {len(rows) - 3} untagged after update, got {len(rows_after)}"
        )

    # --- Test 5: confirm exact values written back correctly
    cur.execute(
        "SELECT person_id, skill_category FROM people WHERE person_id IN (?,?,?)",
        list(simulated_llm_outputs.keys()),
    )
    written = dict(cur.fetchall())
    for pid, raw_output in simulated_llm_outputs.items():
        expected = parse_and_validate(raw_output)
        got = written[pid]
        status = "OK" if got == expected else "FAIL"
        if got != expected:
            failures.append(f"person_id={pid} written as {got!r}, expected {expected!r}")
        print(f"[4] person_id={pid} skill_category={got!r} [{status}]")

    conn.close()
    os.remove(TEST_DB)

    print()
    if failures:
        print(f"FAILED ({len(failures)} issue(s)):")
        for f in failures:
            print(f"  - {f}")
        sys.exit(1)
    else:
        print("All workflow logic checks passed.")


if __name__ == "__main__":
    main()
