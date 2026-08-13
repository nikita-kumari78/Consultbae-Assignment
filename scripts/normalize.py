"""
Normalization helpers used by the merge pipeline.

These exist because the three source files encode the same real-world
values (phone numbers, cities, emails, dates, money) in inconsistent ways.
Every function here is deliberately narrow and testable so the matching
logic in merge.py can be trusted.
"""
import re
from datetime import datetime

# --- City alias table -------------------------------------------------
# Built by eyeballing the raw files. Same city, different strings.
CITY_ALIASES = {
    "gurgaon": "Gurgaon", "gurugram": "Gurgaon",
    "bangalore": "Bengaluru", "bengaluru": "Bengaluru",
    "delhi": "Delhi", "new delhi": "Delhi", "delhi ncr": "Delhi",
    "noida": "Noida",
    "pune": "Pune",
}


def norm_city(raw):
    if raw is None or str(raw).strip() == "":
        return None
    key = str(raw).strip().lower()
    return CITY_ALIASES.get(key, str(raw).strip().title())


def norm_email(raw):
    if raw is None or str(raw).strip() == "":
        return None
    return str(raw).strip().lower()


def norm_phone(raw):
    """
    Collapse +91 / 91 / 0 prefixed Indian mobile numbers down to a bare
    10-digit string so the same number in different formats matches.
    Returns None if we can't extract something that looks like a valid
    10-digit Indian mobile number.
    """
    if raw is None or str(raw).strip() == "":
        return None
    digits = re.sub(r"\D", "", str(raw))  # strip +, -, spaces, etc.
    if len(digits) == 12 and digits.startswith("91"):
        digits = digits[2:]
    elif len(digits) == 11 and digits.startswith("0"):
        digits = digits[1:]
    if len(digits) == 10:
        return digits
    return None  # malformed, don't guess


def norm_name(raw):
    if raw is None or str(raw).strip() == "":
        return None
    # collapse whitespace, title-case for display
    cleaned = re.sub(r"\s+", " ", str(raw).strip())
    return cleaned.title()


def name_key(raw):
    """Lowercase, no punctuation -- used only for fuzzy matching, not display."""
    n = norm_name(raw)
    if n is None:
        return None
    return re.sub(r"[^a-z ]", "", n.lower()).strip()


def parse_messy_date(raw):
    """
    Source1's Applied Date column mixes at least 4 formats:
      24-07-2026, 2026-08-08, 01-08-2026, 7 Jul 2026, 07/13/2026
    Try each known format in turn; return ISO date string or None.
    """
    if raw is None or str(raw).strip() == "":
        return None
    raw = str(raw).strip()
    formats = [
        "%d-%m-%Y",   # 24-07-2026
        "%Y-%m-%d",   # 2026-08-08
        "%d %b %Y",   # 7 Jul 2026
        "%m/%d/%Y",   # 07/13/2026 (day=13 rules out DD/MM, must be MM/DD)
    ]
    for fmt in formats:
        try:
            return datetime.strptime(raw, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return None  # unparseable -- logged as a data issue, not silently dropped


def norm_ctc_annual_inr(raw):
    """
    Source1 'Current CTC' mixes raw annual INR (417964) with what looks
    like LPA shorthand (4.2, 8.3, 11.2 -- i.e. lakhs per annum).
    Heuristic: any value under 100 is almost certainly LPA (no one's
    annual CTC is genuinely <100 INR), so multiply by 100,000.
    """
    if raw is None or str(raw).strip() == "":
        return None, None
    try:
        val = float(raw)
    except ValueError:
        return None, None
    if val < 100:
        return round(val * 100000), "inferred_lpa_shorthand"
    return round(val), "raw_annual"


def norm_rate_monthly_inr(raw):
    """
    Source2 'rate' mixes hourly ('1415/hr') and monthly ('72k/month').
    Normalize both to an estimated monthly INR figure so they're
    comparable. Hourly -> monthly assumes 8hr/day, 22 working days/month
    (standard gig-platform convention) -- documented, not hidden.
    """
    if raw is None or str(raw).strip() == "":
        return None, None
    raw = str(raw).strip().lower()
    m = re.match(r"^([\d.]+)/hr$", raw)
    if m:
        hourly = float(m.group(1))
        return round(hourly * 8 * 22), "converted_from_hourly"
    m = re.match(r"^([\d.]+)k/month$", raw)
    if m:
        monthly = float(m.group(1)) * 1000
        return round(monthly), "raw_monthly"
    return None, None


def norm_status(raw):
    if raw is None or str(raw).strip() == "":
        return None
    v = str(raw).strip().lower()
    mapping = {"active": "Active", "inactive": "Inactive", "paused": "Paused"}
    return mapping.get(v, str(raw).strip().title())


def norm_verified(raw):
    if raw is None or str(raw).strip() == "":
        return None
    v = str(raw).strip().lower()
    if v in ("y", "yes"):
        return True
    if v in ("n", "no"):
        return False
    return None


def norm_skills(raw):
    """Split, trim, lowercase, dedupe a comma-separated skills string."""
    if raw is None or str(raw).strip() == "":
        return []
    parts = [s.strip().lower() for s in str(raw).split(",")]
    parts = [p for p in parts if p]
    # collapse trivial spelling variants seen across files
    canon = {"rest apis": "rest apis", "web scraping": "web scraping"}
    out = []
    seen = set()
    for p in parts:
        p = canon.get(p, p)
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out
