#!/usr/bin/env python3
"""Fetch open llvm-project PRs awaiting review, scored for triage.

Unions three GitHub searches (review-requested / reviewed-by / mentions),
dedupes, tags each PR with an area and signals, and prints scored JSON on stdout
for the /review-queue skill to rank. The score is a floor the skill refines;
retune it via the weights below.

Usage: review-queue.py [--repo OWNER/REPO] [--user LOGIN|@me] [--limit N] [--enrich]
Requires an authenticated `gh` CLI.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone

# Higher weight ranks an area first. dsymutil is code-owned and low-volume (every
# one gets reviewed); lldb is code-owned but high-traffic; debug-info,
# binary-utilities and wasm are group-review areas.
CATEGORY_WEIGHTS = {
    "dsymutil": 50,
    "lldb": 40,
    "debug-info": 20,
    "binary-utilities": 10,
    "wasm": 10,
    "other": 5,
}

# Additive on top of the area weight. `mentioned` is deliberately low: LLVM's bot
# @-mentions code owners on nearly every in-area PR, so it barely discriminates --
# actually engaging (reviewed_and_requested) is the signal that carries weight.
SIGNAL_WEIGHTS = {
    "reviewed_and_requested": 40,
    "reviewed_before": 20,
    "code_owner": 10,
    "mentioned": 10,
}

# Recently-active PRs score higher; long-idle ones are likely abandoned. (max_idle, points)
FRESHNESS = [(3, 15), (14, 8), (30, 3), (90, 0)]
STALE_IDLE_DAYS = 90
STALE_PENALTY = -20

# A PR open a while but still active is worth a nudge; one gone quiet is not.
AGING_MIN_AGE_DAYS = 14
AGING_MAX_IDLE_DAYS = 30
AGING_BONUS = 10

DRAFT_PENALTY = -40
BOT_PENALTY = -20

# Cutoffs for suggested_bucket.
BUCKET_MUST = 75
BUCKET_SHOULD = 45

# LLVM's PR labeler applies these area labels; they map to the coarse categories.
LABEL_CATEGORY = {
    "lldb": "lldb",
    "lldb-dap": "lldb",
    "debuginfo": "debug-info",
    "llvm:binary-utilities": "binary-utilities",
    "lld:wasm": "wasm",
    "backend:WebAssembly": "wasm",
}

# dsymutil/DWARFLinker/dwarfutil have no label of their own; the title identifies them.
DSYMUTIL_RE = re.compile(r"\b(dsymutil|dwarflinker|dwarf-?util)\b", re.IGNORECASE)

# Source tag -> the gh search flag that produces it.
QUERIES = {
    "requested": "--review-requested",
    "reviewed": "--reviewed-by",
    "mentioned": "--mentions",
}
FIELDS = "number,title,labels,createdAt,updatedAt,url,author,isDraft,commentsCount"

NOW = datetime.now(timezone.utc)


def gh(args):
    """Runs `gh` and returns (stdout, ok)."""
    proc = subprocess.run(["gh", *args], capture_output=True, text=True)
    if proc.returncode != 0:
        print(f"warning: `gh {' '.join(args)}` failed: {proc.stderr.strip()}",
              file=sys.stderr)
        return "", False
    return proc.stdout, True


def gh_search(repo, user, limit, flag):
    out, ok = gh([
        "search", "prs", "--repo", repo, flag, user, "--state", "open",
        "--limit", str(limit), "--json", FIELDS,
    ])
    if not ok:
        return []
    rows = json.loads(out or "[]")
    if len(rows) >= limit:
        print(f"warning: query {flag} hit the --limit of {limit}; results may be "
              f"truncated. Re-run with a higher --limit.", file=sys.stderr)
    return rows


def parse_dt(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def categorize(labels, title):
    """Returns the highest-weight area this PR belongs to."""
    cats = set()
    if DSYMUTIL_RE.search(title):
        cats.add("dsymutil")
    for lab in {l["name"] for l in labels}:
        if lab in LABEL_CATEGORY:
            cats.add(LABEL_CATEGORY[lab])
    if not cats:
        return "other"
    return max(cats, key=lambda c: CATEGORY_WEIGHTS.get(c, 0))


def score(pr):
    """Returns base_score and human-readable signals for a merged PR record."""
    signals = []
    points = CATEGORY_WEIGHTS.get(pr["category"], 0)
    src = set(pr["sources"])

    if "requested" in src:
        points += SIGNAL_WEIGHTS["code_owner"]
        signals.append("code-owner review request")
    if "mentioned" in src:
        points += SIGNAL_WEIGHTS["mentioned"]
        signals.append("@-mentioned")
    if "reviewed" in src and "requested" in src:
        points += SIGNAL_WEIGHTS["reviewed_and_requested"]
        signals.append("re-requested after your review (your court)")
    elif "reviewed" in src:
        points += SIGNAL_WEIGHTS["reviewed_before"]
        signals.append("you reviewed it before")

    idle = pr["idle_days"]
    age = pr["age_days"]
    if idle > STALE_IDLE_DAYS:
        points += STALE_PENALTY
        signals.append(f"stale ({idle}d idle)")
    else:
        for max_idle, pts in FRESHNESS:
            if idle <= max_idle:
                points += pts
                break
        if idle <= 3:
            signals.append("active in last 3d")
    if age >= AGING_MIN_AGE_DAYS and idle <= AGING_MAX_IDLE_DAYS:
        points += AGING_BONUS
        signals.append(f"waiting {age}d, still active")

    if pr["draft"]:
        points += DRAFT_PENALTY
        signals.append("draft")
    if pr["author_is_bot"]:
        points += BOT_PENALTY
        signals.append("bot-authored")

    if pr.get("updated_since_review"):
        signals.append(f"{pr.get('commits_since_review', '?')} commit(s) since your review")

    return points, signals


def enrich(pr, repo, me):
    """Flags whether the PR gained commits after the last review (one gh call per PR)."""
    out, ok = gh([
        "pr", "view", str(pr["number"]), "--repo", repo,
        "--json", "reviews,commits",
    ])
    if not ok:
        return
    data = json.loads(out or "{}")
    my_reviews = [parse_dt(r["submittedAt"]) for r in data.get("reviews", [])
                  if (r.get("author") or {}).get("login") == me and r.get("submittedAt")]
    if not my_reviews:
        return
    last_review = max(my_reviews)
    newer = [c for c in data.get("commits", [])
             if c.get("committedDate") and parse_dt(c["committedDate"]) > last_review]
    pr["commits_since_review"] = len(newer)
    pr["updated_since_review"] = bool(newer)


BUCKET_ORDER = ["must", "should", "optional"]
OPTIONAL_CAP = 20  # text output truncates the noisy optional bucket unless --all


def render_text(result, show_all=False, out=sys.stdout):
    """Prints the queue as a grouped, ranked list for reading in a terminal."""
    tty = out.isatty()
    dim = lambda s: f"\033[2m{s}\033[0m" if tty else s
    bold = lambda s: f"\033[1m{s}\033[0m" if tty else s
    width = shutil.get_terminal_size((100, 20)).columns

    prs = result["prs"]
    by_cat = {}
    for p in prs:
        by_cat[p["category"]] = by_cat.get(p["category"], 0) + 1
    print(bold(f"{result['count']} PRs awaiting review in {result['repo']}"), file=out)
    print(dim("  ".join(f"{k}={v}" for k, v in sorted(by_cat.items()))), file=out)

    for bucket in BUCKET_ORDER:
        items = [p for p in prs if p["suggested_bucket"] == bucket]
        if not items:
            continue
        hidden = 0
        if bucket == "optional" and not show_all and len(items) > OPTIONAL_CAP:
            hidden = len(items) - OPTIONAL_CAP
            items = items[:OPTIONAL_CAP]
        print(file=out)
        print(bold(f"{bucket.upper()} ({len(items) + hidden})"), file=out)
        for p in items:
            head = f"{p['base_score']:>4}  {p['category']:<16} #{p['number']:<7} "
            avail = max(20, width - len(head))
            title = p["title"]
            if len(title) > avail:
                title = title[:avail - 1] + "…"
            print(head + title, file=out)
            signals = " · ".join(p["signals"]) if p["signals"] else "no signals"
            print(dim(f"      {signals} · {p['idle_days']}d idle · {p['url']}"), file=out)
        if hidden:
            print(dim(f"      … +{hidden} more (use --all)"), file=out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo", default="llvm/llvm-project")
    ap.add_argument("--user", default="@me")
    ap.add_argument("--limit", type=int, default=400)
    ap.add_argument("--enrich", action="store_true",
                    help="check per-PR whether reviewed PRs changed since the last "
                         "review (one gh call each; slower)")
    ap.add_argument("--format", choices=("auto", "json", "text"), default="auto",
                    help="output format; auto = text on a terminal, json when piped")
    ap.add_argument("--all", action="store_true", dest="show_all",
                    help="in text output, list every PR (default caps the optional bucket)")
    args = ap.parse_args()

    # A concrete login is needed to drop own-authored PRs and match past reviews.
    me = args.user
    if me == "@me":
        out, ok = gh(["api", "user", "--jq", ".login"])
        me = out.strip() if ok and out.strip() else "@me"

    merged = {}
    for tag, flag in QUERIES.items():
        for row in gh_search(args.repo, args.user, args.limit, flag):
            num = row["number"]
            rec = merged.get(num)
            if rec is None:
                rec = dict(row)
                rec["sources"] = []
                merged[num] = rec
            rec["sources"].append(tag)

    prs = []
    for rec in merged.values():
        author = rec.get("author") or {}
        # Own-authored PRs leak in through the mentions query and are excluded.
        if author.get("login") == me:
            continue
        created = parse_dt(rec["createdAt"])
        updated = parse_dt(rec["updatedAt"])
        pr = {
            "number": rec["number"],
            "title": rec["title"],
            "url": rec["url"],
            "author": author.get("login"),
            "author_is_bot": bool(author.get("is_bot")),
            "labels": [l["name"] for l in rec.get("labels", [])],
            "sources": sorted(set(rec["sources"])),
            "draft": bool(rec.get("isDraft")),
            "comments": rec.get("commentsCount", 0),
            "age_days": (NOW - created).days,
            "idle_days": (NOW - updated).days,
            "created_at": rec["createdAt"],
            "updated_at": rec["updatedAt"],
        }
        pr["category"] = categorize(rec.get("labels", []), pr["title"])
        prs.append(pr)

    if args.enrich:
        for pr in prs:
            if "reviewed" in pr["sources"]:
                enrich(pr, args.repo, me)

    for pr in prs:
        pr["base_score"], pr["signals"] = score(pr)
        pr["suggested_bucket"] = (
            "must" if pr["base_score"] >= BUCKET_MUST else
            "should" if pr["base_score"] >= BUCKET_SHOULD else
            "optional"
        )

    prs.sort(key=lambda p: p["base_score"], reverse=True)

    result = {"repo": args.repo, "user": me, "generated_at": NOW.isoformat(),
              "count": len(prs), "prs": prs}

    fmt = args.format
    if fmt == "auto":
        fmt = "text" if sys.stdout.isatty() else "json"

    if fmt == "text":
        render_text(result, show_all=args.show_all)
        return

    by_cat = {}
    for pr in prs:
        by_cat[pr["category"]] = by_cat.get(pr["category"], 0) + 1
    print(f"fetched {len(prs)} open PR(s) for {me} in {args.repo}: "
          + ", ".join(f"{k}={v}" for k, v in sorted(by_cat.items())), file=sys.stderr)

    json.dump(result, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
