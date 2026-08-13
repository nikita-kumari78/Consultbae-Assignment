# Task 4 — Data Issues Report

Source1 = Naukri applicants (41 data rows), Source2 = gig workers (31 data rows,
after dropping one blank row), Source3 = CBNexus contacts (30 data rows, after
dropping one duplicate embedded header). Merge produced **57 unique people**
from 102 total input records.

## 1. No shared ID across sources
Source1 has email + phone, Source2 has only email, Source3 has only phone.
There is no column common to all three. **Fix:** matched people using a
union-find over normalized phone and normalized email, with Source1 acting
as the bridge between Source2 (email) and Source3 (phone). See §7 for the
one case this couldn't resolve safely.

## 2. Phone number formats (all 3 files)
Same numbers written as `+919000000254`, `9000000237`, `09000000287`,
`919000000231`, `+91-9000000131`. **Fix:** stripped all non-digits, then
removed a leading `91` (12 digits) or leading `0` (11 digits) to get a bare
10-digit number used as the matching key.

## 3. City name variants (all 3 files)
`Gurgaon`/`Gurugram`, `Bangalore`/`Bengaluru`, `Delhi`/`New Delhi`/`Delhi NCR`
are the same places written differently, plus inconsistent casing and
trailing whitespace (`"Noida "`). **Fix:** alias table mapping all variants
to one canonical spelling before matching and storage.

## 4. Email casing inconsistent (Source2)
Some emails are ALL CAPS (`ISHA.CHOPRA95@MAILTEST.EXAMPLE.ORG`), most are
lowercase. Email is a matching key, so uppercase entries would have silently
failed to match their Source1 counterpart. **Fix:** lowercase + trim every
email before comparison and storage.

## 5. Inconsistent units in money fields
- Source1 `Current CTC`: mixes raw annual INR (`417964`) with what looks
  like lakhs-per-annum shorthand (`4.2`, `8.3`, `11.2`). 21 of 41 rows were
  in this shorthand form. **Fix:** any value under 100 is treated as LPA and
  multiplied by 100,000; the normalization method used is stored alongside
  the value (`ctc_normalization_method`) so it's auditable, not hidden.
- Source2 `rate`: mixes hourly (`1415/hr`) and monthly (`72k/month`) pay.
  **Fix:** normalized both to an estimated monthly INR figure (hourly ×8hr
  ×22 working days), with the conversion method stored per record.

Both of these are heuristics on ambiguous data, not certainties — flagged
here explicitly rather than presented as clean numbers.

## 6. Inconsistent date formats (Source1 `Applied Date`)
Same column contains `24-07-2026` (DD-MM-YYYY), `2026-08-08` (YYYY-MM-DD),
`7 Jul 2026`, and `07/13/2026` (MM/DD/YYYY — the day value of 13 rules out
DD/MM). **Fix:** tried each known format in turn and parsed to ISO
`YYYY-MM-DD`. All 41 rows parsed successfully.

## 7. Duplicate / corrupted rows within a single source
- **Source1:** one row ("R. Verma") is an exact duplicate of another row
  ("Rohit Verma") — same email, same phone, same CTC. Deduped, kept the
  fuller name.
- **Source1:** "Nikhil Chopra" appears twice with two different email
  addresses (`nikhil.chopra70@...` and `alt.nikhil.chopra70@...`) but the
  same phone number and identical experience/CTC/date — clearly the same
  person with an alias email. Matched via phone, both emails preserved in
  the audit trail (`person_source_records`).
- **Source2:** one row is fully blank — dropped.
- **Source2:** one row has its columns shifted by one position (skill tags
  ended up in the `email_id` column). Detected because the "email" field
  contained no `@`. Reconstructed the row from the shifted columns; the
  true `status` value for that row was pushed off the end and unrecoverable,
  so it's stored as NULL rather than guessed.
- **Source3:** the file contains a second, duplicate header row partway
  through, as if two exports were concatenated. Detected and dropped.

## 8. Unresolved identity conflict — flagged, not auto-merged
Two records named "Arjun Mehta" in the same city (Noida) have **different**
phone numbers (`9000000131` vs `9000000272`) in Source3, while Source1 and
Source2 each show a third, distinct email for an "Arjun Mehta" in Noida.
This could be one person with a data-entry error, or two different real
people who happen to share a common name and city. The pipeline does not
guess — it logs this to a `match_conflicts` table and leaves the records
unmerged, pending human review. This was a deliberate design choice: silently
merging on name+city alone risks conflating two different people, which is
worse than an unresolved flag.

## Summary of automated fixes vs. flags
| Category | Count | Handling |
|---|---|---|
| CTC unit correction | 21 | Auto-fixed, method logged |
| Exact duplicate row | 1 | Auto-deduped |
| Alias-email same person | 1 | Auto-merged via phone |
| Blank row | 1 | Dropped |
| Column-shifted row | 1 | Reconstructed |
| Duplicate header row | 1 | Dropped |
| Ambiguous identity | 1 | Flagged, NOT merged |

Full machine-readable log: `reports/data_issues_log.json`.
