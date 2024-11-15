#!/usr/bin/env python3

import argparse
import logging
import shutil
import subprocess
import sys

from rich.logging import RichHandler

log = logging.getLogger(__name__)

mnemonics = {
    "next": "next",
    "bastille": "apple/stable/20200714",
    "ganymede": "apple/stable/20210107",
    "fbi": "stable/20210726",
    "austria": "stable/20211026",
    "rome": "stable/20220421",
    "navy": "stable/20221013",
    "rebranch": "stable/20230725",
    "main": "stable/20230725",
}


def run(command, check=True):
    log.debug(" ".join(command))
    try:
        p = subprocess.run(command, capture_output=True, check=check)
        if p.stderr:
            log.debug(p.stderr.decode("utf-8").strip())
        if p.stdout:
            log.debug(p.stdout.decode("utf-8").strip())
        return p.returncode
    except subprocess.CalledProcessError as e:
        if e.stderr:
            log.error(e.stderr.decode("utf-8").strip())
        if e.stdout:
            log.error(e.stdout.decode("utf-8").strip())
        raise e


def get_short_hash(hash):
    command = ["git", "rev-parse", "--short", hash]
    log.debug(" ".join(command))
    return (
        subprocess.check_output(command, stderr=subprocess.PIPE).decode("utf8").strip()
    )


def get_commit(hash, format="%h %s"):
    command = ["git", "show", f"--pretty=format:{format}", "-s", hash]
    log.debug(" ".join(command))
    return (
        subprocess.check_output(command, stderr=subprocess.PIPE).decode("utf8").strip()
    )


def add_remote(name, url, no_push=False):
    if run(["git", "ls-remote", "--exit-code", name], check=False) != 0:
        log.debug(f"Adding remote {name}: {url}")
        run(["git", "remote", "add", name, url])
    if no_push:
        run(["git", "remote", "set-url", "--push", name, "/dev/null"])


def get_branch(target):
    if target in mnemonics:
        return mnemonics[target]
    try:
        major, minor = tuple(map(int, (target.split("."))))
        return f"swift/release/{major}.{minor}"
    except ValueError:
        return target


def main():
    parser = argparse.ArgumentParser(
        description="Cherrypick commits to Apple stable and release branches."
    )

    parser.add_argument(
        "branch", help="The base branch name, mnemonic or release version.", type=str
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Print logging output."
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Don't push changes or create a PR. ",
    )
    parser.add_argument(
        "-p",
        "--pr-only",
        action="store_true",
        help="Skip everything before pushing the branch and creating the PR. Used after resolving conflicts.",
    )
    parser.add_argument("commits", help="git commit hash", type=str, nargs="+")
    args = parser.parse_args()

    # Configure logging.
    level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=level, format="%(message)s", datefmt="[%X]", handlers=[RichHandler()]
    )

    # Make sure we have gh installed.
    if not shutil.which("gh"):
        log.error("GitHub command-line tool (gh) not found in path.")
        return 1

    # Make sure we have remotes for upstream LLVM and downstream Swift.
    add_remote("llvm", "git@github.com:llvm/llvm-project.git", no_push=True)
    add_remote("swift", "git@github.com:swiftlang/llvm-project.git")

    # Fetch upstream LLVM.
    if not args.pr_only:
        run(["git", "fetch", "-q", "--multiple", "origin", "llvm"])

    base_branch = get_branch(args.branch)

    short_commits = [get_short_hash(c) for c in args.commits]
    dashed_commits = "-".join(short_commits)
    target_branch = f"cherrypick-{dashed_commits}"

    last_commit_title = get_commit(args.commits[-1], "%s")
    title = f"[🍒 {base_branch}] {last_commit_title}"

    log.info(f"creating cherry-pick PR: {title}")
    for commit in args.commits:
        log.info(get_commit(commit))

    if not args.pr_only:
        # Check out the branch we want to cherry pick to.
        run(["git", "checkout", base_branch])

        # Create a new named branch that contains the names of the commits.
        try:
            run(["git", "checkout", "-b", target_branch])
        except subprocess.CalledProcessError:
            log.info(f"delete the target branch with: git branch -D {target_branch}")
            return 1

        # Cherry pick commits one-by-one.
        for commit in args.commits:
            try:
                run(["git", "cherry-pick", "-x", commit])
            except subprocess.CalledProcessError:
                return 1

    # Don't push or create the PR if this is a dry-run.
    if not args.dry_run:
        # Push the changes to the swift remote.
        run(["git", "push", "--set-upstream", "swift", target_branch])

        # Use the GitHub command line tool to open the browser.
        run(
            [
                "gh",
                "pr",
                "create",
                "--fill-verbose",
                "--title",
                title,
                "--repo",
                "swiftlang/llvm-project",
                "--base",
                base_branch,
                "--web",
            ]
        )


if __name__ == "__main__":
    sys.exit(main())
