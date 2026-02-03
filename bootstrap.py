#!/usr/bin/env python3

"""Bootstrap script for dotfiles setup and configuration."""

import argparse
import logging
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

FORMAT = "%(message)s"

try:
    from rich.logging import RichHandler

    logging.basicConfig(
        level=logging.INFO, format=FORMAT, datefmt="[%X]", handlers=[RichHandler()]
    )
except ImportError:
    logging.basicConfig(
        level=logging.INFO, format=FORMAT, datefmt="[%X]", stream=sys.stdout
    )

logger = logging.getLogger(__name__)


class DotfilesBootstrap:
    """Handles dotfiles synchronization and system configuration."""

    def __init__(self):
        self.dotfiles_dir = Path(__file__).parent.resolve()
        self.home_dir = Path.home()

    def update(self) -> None:
        """Update the dotfiles repository from origin."""
        logger.info("Updating")
        subprocess.run(
            ["git", "pull", "origin", "main"], cwd=self.dotfiles_dir, check=True
        )

    def git_config(self) -> None:
        """Configure Git settings."""
        logger.info("Configuring Git")

        # Configure global .gitignore
        logger.info("Configuring global .gitignore")
        gitignore_global = self.home_dir / ".gitignore_global"
        subprocess.run(
            ["git", "config", "--global", "core.excludesfile", str(gitignore_global)],
            check=True,
        )

        # Configure Araxis Merge if available
        araxis_path = Path("/Applications/Araxis Merge.app/Contents/Utilities/")
        if araxis_path.exists():
            logger.info("Configuring Araxis Merge")
            subprocess.run(
                ["git", "config", "--global", "diff.guitool", "araxis"], check=True
            )
            subprocess.run(
                ["git", "config", "--global", "merge.guitool", "araxis"], check=True
            )
            subprocess.run(
                [
                    "git",
                    "config",
                    "--global",
                    "mergetool.araxis.path",
                    "/Applications/Araxis Merge.app/Contents/Utilities/compare",
                ],
                check=True,
            )

        # Configure Sublime Merge if available
        smerge_path = Path(
            "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/"
        )
        if smerge_path.exists():
            logger.info("Configuring Sublime Merge")
            smerge_cmd = (
                "/Applications/Sublime\\ Merge.app/Contents/SharedSupport/bin/smerge "
                'mergetool "$BASE" "$LOCAL" "$REMOTE" -o "$MERGED"'
            )
            subprocess.run(
                ["git", "config", "--global", "mergetool.smerge.cmd", smerge_cmd],
                check=True,
            )
            subprocess.run(
                ["git", "config", "--global", "mergetool.smerge.trustExitCode", "true"],
                check=True,
            )
            subprocess.run(
                ["git", "config", "--global", "merge.guitool", "smerge"], check=True
            )

        # Configure delta if available
        delta_path = shutil.which("delta")
        if delta_path:
            logger.info("Configuring delta")
            subprocess.run(
                ["git", "config", "--global", "core.pager", "delta"], check=True
            )
            subprocess.run(
                [
                    "git",
                    "config",
                    "--global",
                    "interactive.diffFilter",
                    "delta --color-only",
                ],
                check=True,
            )

    def tool_config(self) -> None:
        """Configure development tools."""
        logger.info("Configuring Tools")

        # Configure fish theme if available
        fish_path = shutil.which("fish")
        if fish_path:
            logger.info("Configuring fish theme")
            solarized_script = self.dotfiles_dir / ".config" / "fish" / "solarized.fish"
            subprocess.run([fish_path, str(solarized_script)], check=True)

    def sync(self) -> None:
        """Synchronize dotfiles to home directory."""
        logger.info("Syncing")

        # Rsync dotfiles to home
        exclude_patterns = [
            ".git/",
            ".gitignore",
            "Preferences.sublime-settings",
            "README.md",
            "bootstrap.sh",
            "bootstrap.py",
            "installers/",
            "os/",
            "scripts/",
            "sublime/",
            "tmux.terminfo",
        ]

        rsync_cmd = ["rsync"]
        for pattern in exclude_patterns:
            rsync_cmd.extend(["--exclude", pattern])

        rsync_cmd.extend(
            [
                "--filter=:- .gitignore",
                "--no-perms",
                "-avh",
                f"{self.dotfiles_dir}/",
                str(self.home_dir),
            ]
        )

        subprocess.run(rsync_cmd, check=True)

        # Touch .localrc so fish can source it
        localrc = self.home_dir / ".localrc"
        localrc.touch(exist_ok=True)

        # Copy Sublime configurations
        sublime_merge_dir = (
            self.home_dir / "Library" / "Application Support" / "Sublime Merge"
        )
        if sublime_merge_dir.exists():
            sublime_merge_src = self.dotfiles_dir / "sublime" / "merge"
            sublime_merge_dst = sublime_merge_dir / "Packages" / "User"
            if sublime_merge_src.exists():
                subprocess.run(
                    ["rsync", "-a", f"{sublime_merge_src}/", str(sublime_merge_dst)],
                    check=True,
                )

        sublime_text_dir = (
            self.home_dir / "Library" / "Application Support" / "Sublime Text"
        )
        if sublime_text_dir.exists():
            sublime_text_src = self.dotfiles_dir / "sublime" / "text"
            sublime_text_dst = sublime_text_dir / "Packages" / "User"
            if sublime_text_src.exists():
                subprocess.run(
                    ["rsync", "-a", f"{sublime_text_src}/", str(sublime_text_dst)],
                    check=True,
                )

    def directories(self) -> None:
        """Create necessary directories."""
        (self.home_dir / "vim" / "undo").mkdir(parents=True, exist_ok=True)
        (self.home_dir / ".ssh").mkdir(parents=True, exist_ok=True)
        (self.home_dir / ".gnupg").mkdir(parents=True, exist_ok=True)

    def install(self) -> None:
        """Install and update software."""
        # Install neovim plugins
        if shutil.which("nvim"):
            logger.info("Installing neovim plugins")
            subprocess.run(["nvim", "--headless", "+Lazy! sync", "+qa"], check=False)
            if shutil.which("pip3"):
                subprocess.run(["pip3", "install", "neovim"], check=False)

        # Install/update tmux plugins
        tpm_dir = self.home_dir / ".tmux" / "plugins" / "tpm"
        if not tpm_dir.exists():
            logger.info("Installing tmux plugins")
            subprocess.run(
                ["git", "clone", "https://github.com/tmux-plugins/tpm", str(tpm_dir)],
                check=True,
            )
            subprocess.run([str(tpm_dir / "bin" / "install_plugins")], check=True)
        else:
            logger.info("Updating tmux plugins")
            subprocess.run([str(tpm_dir / "bin" / "update_plugins"), "all"], check=True)

        # Install/update Rust
        if shutil.which("rustup"):
            logger.info("Updating Rust")
            subprocess.run(["rustup", "update"], check=True)
        else:
            logger.info("Installing Rust")
            rustup_script = Path("/tmp/rustup-init.sh")
            subprocess.run(
                [
                    "curl",
                    "--proto",
                    "=https",
                    "--tlsv1.2",
                    "-sSf",
                    "https://sh.rustup.rs",
                    "-o",
                    str(rustup_script),
                ],
                check=True,
            )
            rustup_script.chmod(0o755)
            subprocess.run([str(rustup_script), "-y"], check=True)

        # Update Homebrew
        if shutil.which("brew"):
            logger.info("Updating Homebrew")
            subprocess.run(["brew", "update"], check=True)
            subprocess.run(["brew", "upgrade"], check=True)

    def permissions(self) -> None:
        """Fix file permissions for sensitive directories."""
        logger.info("Fixing Permissions")

        # Fix .ssh permissions
        ssh_dir = self.home_dir / ".ssh"
        if ssh_dir.exists():
            subprocess.run(["chown", "-R", os.getlogin(), str(ssh_dir)], check=True)

            # Set directory permissions to 700
            for item in ssh_dir.rglob("*"):
                if item.is_dir():
                    item.chmod(0o700)

            # Set private key permissions to 600
            for item in ssh_dir.glob("id_rsa*"):
                if item.is_file():
                    item.chmod(0o600)

            # Set public key permissions to 644
            for item in ssh_dir.glob("*.pub"):
                if item.is_file():
                    item.chmod(0o644)

        # Fix .gnupg permissions
        gnupg_dir = self.home_dir / ".gnupg"
        if gnupg_dir.exists():
            subprocess.run(["chown", "-R", os.getlogin(), str(gnupg_dir)], check=True)

            for item in gnupg_dir.rglob("*"):
                if item.is_file():
                    item.chmod(0o600)
                elif item.is_dir():
                    item.chmod(0o700)

    def os_config(self) -> None:
        """Configure OS-specific settings."""
        logger.info("Configuring OS")

        system = platform.system()
        if system == "Darwin":
            logger.info("Configuring macOS")
            macos_script = self.dotfiles_dir / "os" / "macos.sh"
            if macos_script.exists():
                subprocess.run([str(macos_script)], check=True)
        elif system == "Linux":
            logger.info("Configuring Linux")
            linux_script = self.dotfiles_dir / "os" / "linux.sh"
            if linux_script.exists():
                subprocess.run([str(linux_script)], check=True)

    def do_sync_operation(self) -> None:
        """Perform sync operation with related configurations."""
        self.sync()
        self.git_config()
        self.tool_config()
        self.directories()
        self.permissions()

    def do_all(self) -> None:
        """Perform all operations."""
        self.update()
        self.sync()
        self.git_config()
        self.directories()
        self.permissions()
        self.install()
        self.os_config()


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Bootstrap script for dotfiles setup and configuration.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "-s",
        "--sync",
        action="store_true",
        help="Synchronizes dotfiles to home directory",
    )
    parser.add_argument(
        "-i", "--install", action="store_true", help="Install (extra) software"
    )
    parser.add_argument(
        "-c", "--config", action="store_true", help="Configures your system"
    )
    parser.add_argument(
        "-a", "--all", action="store_true", help="Does all of the above"
    )

    args = parser.parse_args()

    # If no arguments provided, show help.
    if not any([args.sync, args.install, args.config, args.all]):
        parser.print_help()
        return os.EX_USAGE

    bootstrap = DotfilesBootstrap()

    try:
        if args.all:
            bootstrap.do_all()
        else:
            if args.sync:
                bootstrap.do_sync_operation()
            if args.install:
                bootstrap.install()
            if args.config:
                bootstrap.os_config()
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with exit code {e.returncode}")
        return os.EX_SOFTWARE
    except Exception as e:
        logger.error(f"Error: {e}")
        return os.EX_SOFTWARE

    return os.EX_OK


if __name__ == "__main__":
    sys.exit(main())
