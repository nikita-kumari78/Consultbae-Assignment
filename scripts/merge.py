"""
ConsultBae take-home -- Task 1: merge pipeline.

Reads the 3 raw CSVs, fixes known row-level corruption, normalizes
fields, matches the same real person across sources (no shared ID
exists, so we chain through phone/email), and writes everything into
a single SQLite database.

Run:  python scripts/merge.py
"""
import csv
import json
import sqlite3
from pathlib import Path

from normalize import (
    norm_city, norm_email, norm_phone, norm_name, name_key,
    parse_messy_date, norm_ctc_annual_inr, norm_rate_monthly_inr,
    norm_status, norm_verified, norm_skills,
)

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw"
DB_PATH = ROOT / "db" / "consultbae.db"
MYSQL_DUMP_PATH = ROOT / "db" / "consultbae_mysql.sql"
ISSUES = []  # collected as we go, dumped to reports/data_issues_log.json


def log_issue(source, description, row=None):
    ISSUES.append({"source": source, "issue": description, "row": row})


# ---------------------------------------------------------------------
# Union-Find for cross-source identity matching
# ---------------------------------------------------------------------
class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))

    def find(self, x):
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[ra] = rb


# ---------------------------------------------------------------------
# Load + clean each source
# ---------------------------------------------------------------------
def load_source1():
    """Naukri applicants: Full Name, Email, Phone, City, Experience, CTC, Applied Date, Skills."""
    path = RAW / "source1_naukri_applicants.csv"
    rows = []
    seen_keys = set()  # (email, phone) to catch exact duplicate rows
    with open(path, newline="", encoding="utf-8") as f:
        for raw in csv.DictReader(f):
            email = norm_email(raw["Email"])
            phone = norm_phone(raw["Phone"])
            dedupe_key = (email, phone)
            if dedupe_key in seen_keys:
                log_issue("source1", f"Exact duplicate row for {raw['Full Name']} "
                                      f"({email}, {phone}) -- kept first occurrence, dropped repeat.",
                          raw)
                continue
            seen_keys.add(dedupe_key)

            ctc_inr, ctc_method = norm_ctc_annual_inr(raw["Current CTC"])
            if ctc_method == "inferred_lpa_shorthand":
                log_issue("source1", f"CTC value '{raw['Current CTC']}' for {raw['Full Name']} "
                                      f"looks like LPA shorthand, not raw INR -- multiplied by 100,000.", raw)

            applied_date = parse_messy_date(raw["Applied Date"])
            if applied_date is None:
                log_issue("source1", f"Could not parse Applied Date '{raw['Applied Date']}' "
                                      f"for {raw['Full Name']}.", raw)

            if phone is None and raw["Phone"].strip():
                log_issue("source1", f"Phone '{raw['Phone']}' for {raw['Full Name']} "
                                      f"didn't normalize to a valid 10-digit number.", raw)

            rows.append({
                "source": "source1_naukri",
                "raw_name": raw["Full Name"],
                "name": norm_name(raw["Full Name"]),
                "name_key": name_key(raw["Full Name"]),
                "email": email,
                "phone": phone,
                "city": norm_city(raw["City"]),
                "experience_years": float(raw["Experience (Years)"]) if raw["Experience (Years)"] else None,
                "ctc_annual_inr": ctc_inr,
                "ctc_normalization_method": ctc_method,
                "applied_date": applied_date,
                "applied_date_raw": raw["Applied Date"],
                "skills": norm_skills(raw["Skills"]),
            })
    return rows


def load_source2():
    """Gig workers: email_id, worker_name, rate, location, status, skill_tags.
    Known corruption: one fully-blank row, one column-shifted row."""
    path = RAW / "source2_gig_workers.csv"
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        for raw in csv.DictReader(f):
            # Blank row: every field empty
            if all((v or "").strip() == "" for v in raw.values()):
                log_issue("source2", "Fully blank row -- dropped.", raw)
                continue

            # Column-shifted row: email_id field doesn't contain '@',
            # but does contain what look like skill tags. The real data
            # (name/rate/location/status) has been pushed one column to
            # the right, and the email ended up last. We detect it and
            # reconstruct instead of dropping, since the person data is
            # recoverable and turned out to be a dup of an existing row.
            if raw["email_id"] and "@" not in raw["email_id"]:
                log_issue("source2", "Column-shifted row detected (skills ended up in email_id "
                                      "column, fields shifted by one) -- realigned fields.", raw)
                # raw['status'] actually holds the true email in this corrupted row
                fixed_email = raw.get("status")
                fixed_name = raw.get("worker_name")
                fixed_rate = raw.get("rate")
                fixed_location = raw.get("location")
                # the true status got dropped off the end entirely in this row;
                # we don't have it, so leave status null rather than guess
                raw = {
                    "email_id": fixed_email,
                    "worker_name": fixed_name,
                    "rate": fixed_rate,
                    "location": fixed_location,
                    "status": None,
                    "skill_tags": raw["email_id"],
                }

            email = norm_email(raw["email_id"])
            rate_inr, rate_method = norm_rate_monthly_inr(raw["rate"])

            rows.append({
                "source": "source2_gig",
                "raw_name": raw["worker_name"],
                "name": norm_name(raw["worker_name"]),
                "name_key": name_key(raw["worker_name"]),
                "email": email,
                "phone": None,  # not collected by this source
                "city": norm_city(raw["location"]),
                "rate_monthly_inr": rate_inr,
                "rate_normalization_method": rate_method,
                "status": norm_status(raw["status"]),
                "skills": norm_skills(raw["skill_tags"]),
            })
    return rows


def load_source3():
    """CBNexus contacts: Name, Phone Number, City, Verified, Projects Completed.
    Known corruption: header row duplicated mid-file (looks like two exports pasted together)."""
    path = RAW / "source3_cbnexus_contacts.csv"
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        for raw in csv.DictReader(f):
            if raw["Name"] == "Name" and raw["Phone Number"] == "Phone Number":
                log_issue("source3", "Duplicate embedded header row mid-file -- dropped.", raw)
                continue

            phone = norm_phone(raw["Phone Number"])
            if phone is None and raw["Phone Number"].strip():
                log_issue("source3", f"Phone '{raw['Phone Number']}' for {raw['Name']} "
                                      f"didn't normalize to a valid 10-digit number.", raw)

            rows.append({
                "source": "source3_cbnexus",
                "raw_name": raw["Name"],
                "name": norm_name(raw["Name"]),
                "name_key": name_key(raw["Name"]),
                "email": None,  # not collected by this source
                "phone": phone,
                "city": norm_city(raw["City"]),
                "verified": norm_verified(raw["Verified"]),
                "projects_completed": int(raw["Projects Completed"]) if raw["Projects Completed"] else None,
            })
    return rows


# ---------------------------------------------------------------------
# Cross-source matching
# ---------------------------------------------------------------------
def match_people(all_rows):
    """
    all_rows: list of dicts from all 3 sources, each tagged with 'source'.
    Returns: list of clusters (each a list of row-indices believed to be
    the same real person), plus a list of ambiguous-name conflicts to
    flag for manual review (never auto-merged).
    """
    n = len(all_rows)
    uf = UnionFind(n)

    by_email, by_phone = {}, {}
    for i, r in enumerate(all_rows):
        if r["email"]:
            by_email.setdefault(r["email"], []).append(i)
        if r.get("phone"):
            by_phone.setdefault(r["phone"], []).append(i)

    for idxs in by_email.values():
        for j in idxs[1:]:
            uf.union(idxs[0], j)
    for idxs in by_phone.values():
        for j in idxs[1:]:
            uf.union(idxs[0], j)

    # Second pass: link records that only share a name+city and have NOT
    # already been linked via email/phone to anything -- but only if the
    # match is unambiguous with respect to phone/email already present.
    unresolved_conflicts = []
    by_namecity = {}
    for i, r in enumerate(all_rows):
        if r["name_key"] and r["city"]:
            by_namecity.setdefault((r["name_key"], r["city"]), []).append(i)

    for (nk, city), idxs in by_namecity.items():
        if len(idxs) < 2:
            continue
        roots = {uf.find(i) for i in idxs}
        if len(roots) == 1:
            continue  # already the same cluster, nothing to do

        # Check whether merging would contradict distinct known phone/email values
        phones = {all_rows[i]["phone"] for i in idxs if all_rows[i].get("phone")}
        emails = {all_rows[i]["email"] for i in idxs if all_rows[i].get("email")}
        if len(phones) > 1 or len(emails) > 1:
            unresolved_conflicts.append({
                "name_key": nk, "city": city,
                "rows": [{"source": all_rows[i]["source"], "raw_name": all_rows[i]["raw_name"],
                          "email": all_rows[i].get("email"), "phone": all_rows[i].get("phone")}
                         for i in idxs],
                "reason": "Same name + city but conflicting phone/email values across records -- "
                          "could be the same person with a data error, or two different real people. "
                          "NOT auto-merged.",
            })
            continue
        # unambiguous -- safe to merge on name+city alone
        for j in idxs[1:]:
            uf.union(idxs[0], j)

    clusters = {}
    for i in range(n):
        clusters.setdefault(uf.find(i), []).append(i)
    return list(clusters.values()), unresolved_conflicts


# ---------------------------------------------------------------------
# SQLite schema + write
# ---------------------------------------------------------------------
SCHEMA = """
CREATE TABLE people (
    person_id INTEGER PRIMARY KEY AUTOINCREMENT,
    canonical_name TEXT,
    canonical_email TEXT,
    canonical_phone TEXT,
    canonical_city TEXT,
    matched_from_sources TEXT,   -- e.g. "source1_naukri,source2_gig"
    match_confidence TEXT        -- 'exact' (email/phone) or 'name_city'
);

CREATE TABLE person_source_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER REFERENCES people(person_id),
    source TEXT,
    raw_name TEXT,
    raw_data TEXT   -- full normalized row as JSON, for audit/lineage
);

CREATE TABLE skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER REFERENCES people(person_id),
    skill TEXT,
    source TEXT
);

CREATE TABLE naukri_applications (
    person_id INTEGER REFERENCES people(person_id),
    experience_years REAL,
    ctc_annual_inr INTEGER,
    ctc_normalization_method TEXT,
    applied_date TEXT,
    applied_date_raw TEXT
);

CREATE TABLE gig_worker_status (
    person_id INTEGER REFERENCES people(person_id),
    rate_monthly_inr INTEGER,
    rate_normalization_method TEXT,
    status TEXT
);

CREATE TABLE cbnexus_contacts (
    person_id INTEGER REFERENCES people(person_id),
    verified BOOLEAN,
    projects_completed INTEGER
);

CREATE TABLE audio_submissions (
    submission_id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER REFERENCES people(person_id),
    submitted_name TEXT,
    submitted_phone TEXT,
    file_path TEXT,
    duration_sec REAL,
    sample_rate_hz INTEGER,
    bitrate_kbps REAL,
    loudness_dbfs REAL,
    quality_estimate TEXT,
    created_at TEXT
);

CREATE TABLE match_conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name_key TEXT,
    city TEXT,
    detail TEXT
);
"""

# ---------------------------------------------------------------------
# MySQL dialect: same shape as SCHEMA above, but with MySQL types,
# AUTO_INCREMENT, InnoDB engine and real FOREIGN KEY constraints.
# ---------------------------------------------------------------------
MYSQL_SCHEMA = """
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS match_conflicts;
DROP TABLE IF EXISTS audio_submissions;
DROP TABLE IF EXISTS cbnexus_contacts;
DROP TABLE IF EXISTS gig_worker_status;
DROP TABLE IF EXISTS naukri_applications;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS person_source_records;
DROP TABLE IF EXISTS people;

CREATE TABLE people (
    person_id INT AUTO_INCREMENT PRIMARY KEY,
    canonical_name VARCHAR(255),
    canonical_email VARCHAR(255),
    canonical_phone VARCHAR(20),
    canonical_city VARCHAR(100),
    matched_from_sources VARCHAR(255),
    match_confidence VARCHAR(20),
    INDEX idx_email (canonical_email),
    INDEX idx_phone (canonical_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE person_source_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    source VARCHAR(50),
    raw_name VARCHAR(255),
    raw_data JSON,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    skill VARCHAR(100),
    source VARCHAR(50),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE,
    INDEX idx_skill (skill)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE naukri_applications (
    person_id INT,
    experience_years DECIMAL(4,1),
    ctc_annual_inr INT,
    ctc_normalization_method VARCHAR(50),
    applied_date DATE,
    applied_date_raw VARCHAR(50),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE gig_worker_status (
    person_id INT,
    rate_monthly_inr INT,
    rate_normalization_method VARCHAR(50),
    status VARCHAR(20),
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cbnexus_contacts (
    person_id INT,
    verified BOOLEAN,
    projects_completed INT,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE audio_submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    person_id INT,
    submitted_name VARCHAR(255),
    submitted_phone VARCHAR(20),
    file_path VARCHAR(500),
    duration_sec DECIMAL(8,2),
    sample_rate_hz INT,
    bitrate_kbps DECIMAL(8,2),
    loudness_dbfs DECIMAL(6,2),
    quality_estimate VARCHAR(50),
    created_at DATETIME,
    FOREIGN KEY (person_id) REFERENCES people(person_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE match_conflicts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name_key VARCHAR(255),
    city VARCHAR(100),
    detail JSON
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
"""


def _sql_val(v):
    """Render a Python value as a MySQL literal for an INSERT statement."""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("\\", "\\\\").replace("'", "\\'")
    return f"'{s}'"


def build_mysql_dump(all_rows, clusters, conflicts):
    """
    Generate a MySQL-compatible .sql dump (schema + data) from the same
    matched clusters used for the SQLite build, so the matching logic is
    identical -- only the target dialect differs. No live MySQL server is
    available in this environment to execute against directly, so this is
    written out as a plain .sql file for `mysql ... < consultbae_mysql.sql`.
    """
    lines = [MYSQL_SCHEMA.strip(), "", "-- Data", ""]
    person_id = 0

    for cluster in clusters:
        person_id += 1
        rows_for_person = [all_rows[i] for i in cluster]
        name, email, phone, city = pick_canonical(rows_for_person)
        sources = sorted({r["source"] for r in rows_for_person})
        confidence = "exact" if any(r.get("email") or r.get("phone") for r in rows_for_person) else "name_city"

        lines.append(
            "INSERT INTO people (person_id, canonical_name, canonical_email, canonical_phone, "
            "canonical_city, matched_from_sources, match_confidence) VALUES "
            f"({person_id}, {_sql_val(name)}, {_sql_val(email)}, {_sql_val(phone)}, "
            f"{_sql_val(city)}, {_sql_val(','.join(sources))}, {_sql_val(confidence)});"
        )

        for r in rows_for_person:
            raw_json = json.dumps(r, default=str)
            lines.append(
                "INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES "
                f"({person_id}, {_sql_val(r['source'])}, {_sql_val(r['raw_name'])}, {_sql_val(raw_json)});"
            )
            for skill in r.get("skills", []):
                lines.append(
                    "INSERT INTO skills (person_id, skill, source) VALUES "
                    f"({person_id}, {_sql_val(skill)}, {_sql_val(r['source'])});"
                )
            if r["source"] == "source1_naukri":
                lines.append(
                    "INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, "
                    "ctc_normalization_method, applied_date, applied_date_raw) VALUES "
                    f"({person_id}, {_sql_val(r['experience_years'])}, {_sql_val(r['ctc_annual_inr'])}, "
                    f"{_sql_val(r['ctc_normalization_method'])}, {_sql_val(r['applied_date'])}, "
                    f"{_sql_val(r['applied_date_raw'])});"
                )
            elif r["source"] == "source2_gig":
                lines.append(
                    "INSERT INTO gig_worker_status (person_id, rate_monthly_inr, "
                    "rate_normalization_method, status) VALUES "
                    f"({person_id}, {_sql_val(r['rate_monthly_inr'])}, "
                    f"{_sql_val(r['rate_normalization_method'])}, {_sql_val(r['status'])});"
                )
            elif r["source"] == "source3_cbnexus":
                lines.append(
                    "INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES "
                    f"({person_id}, {_sql_val(r['verified'])}, {_sql_val(r['projects_completed'])});"
                )

    for c in conflicts:
        lines.append(
            "INSERT INTO match_conflicts (name_key, city, detail) VALUES "
            f"({_sql_val(c['name_key'])}, {_sql_val(c['city'])}, {_sql_val(json.dumps(c))});"
        )

    MYSQL_DUMP_PATH.parent.mkdir(exist_ok=True)
    with open(MYSQL_DUMP_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def pick_canonical(rows_for_person):
    """From the records believed to be one person, pick the most complete
    values to store as the canonical identity."""
    name = next((r["name"] for r in rows_for_person if r.get("name")), None)
    # prefer the longer/fuller name if multiple variants exist (e.g. "R. Verma" vs "Rohit Verma")
    for r in rows_for_person:
        if r.get("name") and len(r["name"]) > len(name or ""):
            name = r["name"]
    email = next((r["email"] for r in rows_for_person if r.get("email")), None)
    phone = next((r["phone"] for r in rows_for_person if r.get("phone")), None)
    city = next((r["city"] for r in rows_for_person if r.get("city")), None)
    return name, email, phone, city


def build_db(all_rows, clusters, conflicts):
    DB_PATH.parent.mkdir(exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    cur = conn.cursor()

    for cluster in clusters:
        rows_for_person = [all_rows[i] for i in cluster]
        name, email, phone, city = pick_canonical(rows_for_person)
        sources = sorted({r["source"] for r in rows_for_person})
        confidence = "exact" if any(r.get("email") or r.get("phone") for r in rows_for_person) else "name_city"

        cur.execute(
            "INSERT INTO people (canonical_name, canonical_email, canonical_phone, "
            "canonical_city, matched_from_sources, match_confidence) VALUES (?,?,?,?,?,?)",
            (name, email, phone, city, ",".join(sources), confidence),
        )
        person_id = cur.lastrowid

        for r in rows_for_person:
            cur.execute(
                "INSERT INTO person_source_records (person_id, source, raw_name, raw_data) VALUES (?,?,?,?)",
                (person_id, r["source"], r["raw_name"], json.dumps(r, default=str)),
            )
            for skill in r.get("skills", []):
                cur.execute("INSERT INTO skills (person_id, skill, source) VALUES (?,?,?)",
                            (person_id, skill, r["source"]))
            if r["source"] == "source1_naukri":
                cur.execute(
                    "INSERT INTO naukri_applications (person_id, experience_years, ctc_annual_inr, "
                    "ctc_normalization_method, applied_date, applied_date_raw) VALUES (?,?,?,?,?,?)",
                    (person_id, r["experience_years"], r["ctc_annual_inr"],
                     r["ctc_normalization_method"], r["applied_date"], r["applied_date_raw"]),
                )
            elif r["source"] == "source2_gig":
                cur.execute(
                    "INSERT INTO gig_worker_status (person_id, rate_monthly_inr, "
                    "rate_normalization_method, status) VALUES (?,?,?,?)",
                    (person_id, r["rate_monthly_inr"], r["rate_normalization_method"], r["status"]),
                )
            elif r["source"] == "source3_cbnexus":
                cur.execute(
                    "INSERT INTO cbnexus_contacts (person_id, verified, projects_completed) VALUES (?,?,?)",
                    (person_id, r["verified"], r["projects_completed"]),
                )

    for c in conflicts:
        cur.execute("INSERT INTO match_conflicts (name_key, city, detail) VALUES (?,?,?)",
                    (c["name_key"], c["city"], json.dumps(c)))

    conn.commit()
    conn.close()


def main():
    s1 = load_source1()
    s2 = load_source2()
    s3 = load_source3()
    all_rows = s1 + s2 + s3

    clusters, conflicts = match_people(all_rows)

    build_db(all_rows, clusters, conflicts)
    build_mysql_dump(all_rows, clusters, conflicts)

    reports_dir = ROOT / "reports"
    reports_dir.mkdir(exist_ok=True)
    with open(reports_dir / "data_issues_log.json", "w") as f:
        json.dump({"row_level_issues": ISSUES, "match_conflicts": conflicts}, f, indent=2, default=str)

    print(f"Loaded: source1={len(s1)} source2={len(s2)} source3={len(s3)} rows")
    print(f"Merged into {len(clusters)} unique people")
    print(f"Row-level issues logged: {len(ISSUES)}")
    print(f"Unresolved match conflicts (flagged, not auto-merged): {len(conflicts)}")
    print(f"SQLite DB written to {DB_PATH}")
    print(f"MySQL dump written to {MYSQL_DUMP_PATH}")


if __name__ == "__main__":
    main()
