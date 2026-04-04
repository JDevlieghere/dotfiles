#!/usr/bin/env python3

import argparse
import collections
import math
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta


def run(command):
    try:
        p = subprocess.run(command, capture_output=True, check=True, text=True)
        return p.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def is_git_repo():
    return run(["git", "rev-parse", "--is-inside-work-tree"]) == "true"


def get_current_user_email():
    return run(["git", "config", "user.email"])


def get_default_branch():
    """Try to detect the default branch name."""
    for ref in ["refs/remotes/origin/HEAD", "refs/heads/main", "refs/heads/master"]:
        result = run(["git", "rev-parse", "--verify", "--quiet", ref])
        if result:
            if ref == "refs/remotes/origin/HEAD":
                symbolic = run(["git", "symbolic-ref", ref])
                if symbolic:
                    return symbolic.split("/")[-1]
            return ref.split("/")[-1]
    return "main"


def get_changed_files(ref, base):
    """Get the list of files changed in the given ref or vs a base branch."""
    if ref and ".." in ref:
        output = run(["git", "diff", "--name-only", "-M", ref])
    elif ref:
        output = run(
            ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "-M", ref]
        )
    elif base:
        merge_base = run(["git", "merge-base", "HEAD", base])
        if not merge_base:
            print(f"error: could not find merge base with '{base}'", file=sys.stderr)
            sys.exit(1)
        output = run(["git", "diff", "--name-only", "-M", merge_base, "HEAD"])
    else:
        return []

    if not output:
        return []
    return [f for f in output.splitlines() if f]


def build_mailmap(emails):
    """Build a mapping from raw emails to canonical (name, email).

    Uses git check-mailmap --stdin to batch-resolve all emails in one call,
    then falls back to grouping by display name for emails not in .mailmap.
    """
    if not emails:
        return {}, {}

    canonical = {}  # raw_email -> canonical_email
    names = {}  # canonical_email -> display_name

    # Batch resolve via git check-mailmap --stdin (single subprocess call)
    stdin = "\n".join(f"<{e}>" for e in emails)
    try:
        p = subprocess.run(
            ["git", "check-mailmap", "--stdin"],
            input=stdin,
            capture_output=True,
            check=True,
            text=True,
        )
        for raw_email, line in zip(emails, p.stdout.strip().splitlines()):
            if "<" in line and ">" in line:
                canon_email = line.split("<")[-1].rstrip(">")
                canon_name = line.split("<")[0].strip()
                canonical[raw_email] = canon_email
                if canon_name:
                    names[canon_email] = canon_name
            else:
                canonical[raw_email] = raw_email
    except (subprocess.CalledProcessError, FileNotFoundError):
        for e in emails:
            canonical[e] = e

    # For emails without a display name, collect from git log
    missing = {e for e in emails if canonical.get(e, e) not in names}
    if missing:
        output = run(["git", "log", "--format=%ae\t%aN", "-5000"])
        if output:
            for line in output.splitlines():
                parts = line.split("\t", 1)
                if len(parts) == 2 and parts[0] in missing:
                    canon = canonical.get(parts[0], parts[0])
                    if canon not in names:
                        names[canon] = parts[1]
                    missing.discard(parts[0])
                if not missing:
                    break

    # Group emails that share the same canonical display name
    name_to_canonical = {}
    for email in emails:
        canon = canonical.get(email, email)
        name = names.get(canon, "")
        if not name:
            continue
        norm = name.lower().strip()
        if norm in name_to_canonical:
            existing = name_to_canonical[norm]
            if canon != existing:
                # Merge: rewrite all emails pointing to canon -> existing
                old_canon = canon
                for e2, c2 in list(canonical.items()):
                    if c2 == old_canon:
                        canonical[e2] = existing
                # Carry over the display name if the target doesn't have one
                if existing not in names and old_canon in names:
                    names[existing] = names[old_canon]
        else:
            name_to_canonical[norm] = canon

    return canonical, names


def canonicalize_counts(counts, canonical):
    """Merge counts for emails that map to the same canonical email."""
    merged = collections.Counter()
    for email, count in counts.items():
        merged[canonical.get(email, email)] += count
    return merged


def get_blame_authors(filepath):
    """Parse git blame output to count lines per author email."""
    output = run(["git", "blame", "--line-porcelain", "HEAD", "--", filepath])
    if not output:
        return {}

    counts = collections.Counter()
    current_email = None
    for line in output.splitlines():
        if line.startswith("author-mail "):
            current_email = line[len("author-mail ") :].strip("<>")
        elif line.startswith("filename ") and current_email:
            counts[current_email] += 1
            current_email = None
    return dict(counts)


def get_log_authors(filepath, since_days):
    """Count commits per author email for a file within a time window."""
    since_date = (datetime.now() - timedelta(days=since_days)).strftime("%Y-%m-%d")
    output = run(
        ["git", "log", f"--since={since_date}", "--format=%ae", "--", filepath]
    )
    if not output:
        return {}
    return dict(collections.Counter(output.splitlines()))


def compute_scores(blame_totals, log_totals, blame_weight=0.6, log_weight=0.4):
    """Combine blame and log signals into a single score per author.

    Uses log normalization to dampen outliers from bulk changes.
    """
    all_authors = set(blame_totals) | set(log_totals)
    if not all_authors:
        return {}

    max_blame = math.log1p(max(blame_totals.values())) if blame_totals else 1
    max_log = math.log1p(max(log_totals.values())) if log_totals else 1

    scores = {}
    for author in all_authors:
        blame_norm = math.log1p(blame_totals.get(author, 0)) / max_blame
        log_norm = math.log1p(log_totals.get(author, 0)) / max_log
        scores[author] = blame_weight * blame_norm + log_weight * log_norm

    return scores


def main():
    parser = argparse.ArgumentParser(
        description="Find relevant reviewers for a commit or branch."
    )
    parser.add_argument(
        "ref",
        nargs="?",
        default=None,
        help="Commit, branch, or range (a..b). Defaults to diff against base branch.",
    )
    parser.add_argument(
        "-n", "--top", type=int, default=5, help="Number of reviewers to show."
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show per-file breakdown."
    )
    parser.add_argument(
        "--base", type=str, default=None, help="Base branch for comparison."
    )
    parser.add_argument(
        "--since",
        type=int,
        default=365,
        help="Only consider log history from the last N days.",
    )
    parser.add_argument(
        "--include-self",
        action="store_true",
        help="Include the current git user in results.",
    )
    args = parser.parse_args()

    if not is_git_repo():
        print("error: not a git repository", file=sys.stderr)
        sys.exit(1)

    current_email = get_current_user_email()

    # Determine mode
    if args.ref:
        files = get_changed_files(args.ref, base=None)
        desc = args.ref
    else:
        base = args.base or get_default_branch()
        files = get_changed_files(None, base=base)
        desc = f"vs {base}"

    if not files:
        print("No changed files found.")
        sys.exit(0)

    # Collect raw per-file data in parallel
    def analyze_file(filepath):
        blame = get_blame_authors(filepath)
        log = get_log_authors(filepath, args.since)
        return filepath, blame, log

    raw_blame_per_file = {}
    raw_log_per_file = {}
    workers = min(len(files), os.cpu_count() or 4)

    with ThreadPoolExecutor(max_workers=workers) as pool:
        for filepath, blame, log in pool.map(analyze_file, files):
            raw_blame_per_file[filepath] = blame
            raw_log_per_file[filepath] = log

    # Gather all unique emails and build mailmap
    all_emails = set()
    for counts in list(raw_blame_per_file.values()) + list(raw_log_per_file.values()):
        all_emails.update(counts.keys())
    if current_email:
        all_emails.add(current_email)
    canonical, names = build_mailmap(sorted(all_emails))

    # Canonicalize current user email for filtering
    current_canonical = canonical.get(current_email, current_email)

    # Canonicalize per-file data and aggregate totals
    blame_totals = collections.Counter()
    log_totals = collections.Counter()
    per_file_blame = {}
    per_file_log = {}

    for filepath in files:
        blame = canonicalize_counts(raw_blame_per_file[filepath], canonical)
        log_counts = canonicalize_counts(raw_log_per_file[filepath], canonical)
        per_file_blame[filepath] = blame
        per_file_log[filepath] = log_counts
        blame_totals.update(blame)
        log_totals.update(log_counts)

    # Filter self
    if not args.include_self and current_canonical:
        blame_totals.pop(current_canonical, None)
        log_totals.pop(current_canonical, None)

    scores = compute_scores(dict(blame_totals), dict(log_totals))
    if not scores:
        print("No reviewers found.")
        sys.exit(0)

    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)[: args.top]

    print(f"Reviewers for {len(files)} changed file(s) ({desc}):\n")
    print(f" {'#':>2}  {'Author':<30} {'Score':>5}  {'Blame':>5}  {'Commits':>7}")
    for i, (email, score) in enumerate(ranked, 1):
        name = names.get(email, email)
        blame = blame_totals.get(email, 0)
        commits = log_totals.get(email, 0)
        print(f" {i:>2}  {name:<30} {score:>5.2f}  {blame:>5}  {commits:>7}")

    if args.verbose:
        print("\nPer-file breakdown:")
        top_emails = {email for email, _ in ranked}
        for filepath in files:
            print(f"\n  {filepath}:")
            file_blame = per_file_blame.get(filepath, {})
            file_log = per_file_log.get(filepath, {})
            file_authors = (set(file_blame) | set(file_log)) & top_emails
            if not args.include_self and current_canonical:
                file_authors.discard(current_canonical)
            for email in sorted(
                file_authors,
                key=lambda e: file_blame.get(e, 0),
                reverse=True,
            ):
                name = names.get(email, email)
                b = file_blame.get(email, 0)
                c = file_log.get(email, 0)
                print(f"    {name:<30} blame:{b:>4}  commits:{c:>3}")


if __name__ == "__main__":
    main()
