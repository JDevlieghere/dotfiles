#!/usr/bin/env python3

"""Configure macOS system settings and preferences.

Inspired by https://mths.be/macos
"""

import logging
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Union

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


class MacOSConfigurator:
    """Handles macOS system configuration and preferences."""

    def __init__(self):
        self.username = os.getlogin()

    def defaults_write(
        self, domain: str, key: str, value_type: str, value: Union[str, dict]
    ) -> None:
        """Helper to write macOS defaults.

        Args:
            domain: The preference domain (e.g., 'com.apple.dock', 'NSGlobalDomain')
            key: The preference key
            value_type: The value type ('-bool', '-int', '-float', '-string', '-dict')
            value: The value to set (or dict for -dict type)
        """
        cmd = ["defaults", "write", domain, key, value_type]

        if value_type == "-dict":
            # For dict type, value should be a dict like {'General': ('bool', 'true')}
            if isinstance(value, dict):
                for k, (vtype, v) in value.items():
                    cmd.extend([k, f"-{vtype}", v])
        else:
            cmd.append(str(value))

        subprocess.run(cmd, check=True)

    def configure_developer_mode(self) -> None:
        """Configure developer mode settings."""
        subprocess.run(
            [
                "sudo",
                "dseditgroup",
                "-o",
                "edit",
                "-a",
                self.username,
                "-t",
                "user",
                "_developer",
            ],
            check=True,
        )
        subprocess.run(
            ["sudo", "DevToolsSecurity", "-enable"],
            check=True,
            stdout=subprocess.DEVNULL,
        )

    def configure_power_management(self) -> None:
        """Configure power management settings."""

        # Automatic restart on power loss
        subprocess.run(["sudo", "pmset", "-a", "autorestart", "1"], check=True)

        # Set the display sleep to 15 minutes
        subprocess.run(["sudo", "pmset", "-a", "displaysleep", "15"], check=True)

        # Disable machine sleep while charging
        subprocess.run(["sudo", "pmset", "-c", "sleep", "0"], check=True)

        # Set machine sleep to 5 minutes on battery
        subprocess.run(["sudo", "pmset", "-b", "sleep", "5"], check=True)

    def configure_system_settings(self) -> None:
        """Configure system settings."""

        # Automatically restart after the system freezes
        subprocess.run(
            ["sudo", "systemsetup", "-setrestartfreeze", "on"],
            check=True,
            stdout=subprocess.DEVNULL,
        )

        # Automatically restart after a power failure
        subprocess.run(
            ["sudo", "systemsetup", "-setrestartpowerfailure", "on"],
            check=True,
            stdout=subprocess.DEVNULL,
        )

    def configure_dock(self) -> None:
        """Configure Dock preferences."""

        # Set the icon size of Dock items to 32 pixels
        self.defaults_write("com.apple.dock", "tilesize", "-int", "32")

        # Enable magnification
        self.defaults_write("com.apple.dock", "magnification", "-int", "1")

        # Set the icon size of Dock items when magnified to 96 pixels
        self.defaults_write("com.apple.dock", "largesize", "-int", "96")

    def configure_activity_monitor(self) -> None:
        """Configure Activity Monitor preferences."""

        # Visualize CPU usage in the Activity Monitor Dock icon
        self.defaults_write("com.apple.ActivityMonitor", "IconType", "-int", "5")

        # Show all processes in Activity Monitor
        self.defaults_write("com.apple.ActivityMonitor", "ShowCategory", "-int", "0")

    def configure_finder(self) -> None:
        """Configure Finder preferences."""

        # Disable animations
        self.defaults_write("com.apple.finder", "DisableAllAnimations", "-bool", "true")

        # Show status bar
        self.defaults_write("com.apple.finder", "ShowStatusBar", "-bool", "true")

        # Disable the warning when changing a file extension
        self.defaults_write(
            "com.apple.finder", "FXEnableExtensionChangeWarning", "-bool", "false"
        )

        # Use list view in all Finder windows by default
        self.defaults_write(
            "com.apple.finder", "FXPreferredViewStyle", "-string", "Nlsv"
        )

        # Expand the following "General" and "Open With" File Info panes
        self.defaults_write(
            "com.apple.finder",
            "FXInfoPanesExpanded",
            "-dict",
            {"General": ("bool", "true"), "OpenWith": ("bool", "true")},
        )

        # Avoid creating .DS_Store files on network or USB volumes
        self.defaults_write(
            "com.apple.desktopservices", "DSDontWriteNetworkStores", "-bool", "true"
        )
        self.defaults_write(
            "com.apple.desktopservices", "DSDontWriteUSBStores", "-bool", "true"
        )

    def configure_screensaver(self) -> None:
        """Configure screensaver preferences."""

        # Immediately require password after screen saver or sleep
        self.defaults_write("com.apple.screensaver", "askForPassword", "-int", "1")
        self.defaults_write("com.apple.screensaver", "askForPasswordDelay", "-int", "0")

    def configure_keyboard_and_mouse(self) -> None:
        """Configure keyboard and mouse preferences."""

        # Disable smart quotes and dashes
        self.defaults_write(
            "NSGlobalDomain", "NSAutomaticQuoteSubstitutionEnabled", "-bool", "false"
        )
        self.defaults_write(
            "NSGlobalDomain", "NSAutomaticDashSubstitutionEnabled", "-bool", "false"
        )

        # Disable auto-correct
        self.defaults_write(
            "NSGlobalDomain", "NSAutomaticSpellingCorrectionEnabled", "-bool", "false"
        )

        # Disable press-and-hold for keys in favor of key repeat
        self.defaults_write(
            "NSGlobalDomain", "ApplePressAndHoldEnabled", "-bool", "false"
        )

        # Increase keyboard repeat rate
        self.defaults_write("NSGlobalDomain", "InitialKeyRepeat", "-int", "10")
        self.defaults_write("NSGlobalDomain", "KeyRepeat", "-int", "1")

        # Disable mouse acceleration
        subprocess.run(
            ["defaults", "write", "NSGlobalDomain", "com.apple.mouse.scaling", "-1"],
            check=True,
        )

    def configure_ui_ux(self) -> None:
        """Configure various UI/UX preferences."""

        # Increase window resize speed for Cocoa applications
        self.defaults_write("NSGlobalDomain", "NSWindowResizeTime", "-float", "0.001")

        # Enable spring loading for directories but remove the delay
        self.defaults_write(
            "NSGlobalDomain", "com.apple.springing.enabled", "-bool", "true"
        )
        self.defaults_write(
            "NSGlobalDomain", "com.apple.springing.delay", "-float", "0"
        )

        # Expand save panel by default
        self.defaults_write(
            "NSGlobalDomain", "NSNavPanelExpandedStateForSaveMode", "-bool", "true"
        )
        self.defaults_write(
            "NSGlobalDomain", "NSNavPanelExpandedStateForSaveMode2", "-bool", "true"
        )

        # Turn off the "Application Downloaded from Internet" quarantine warning
        self.defaults_write(
            "com.apple.LaunchServices", "LSQuarantine", "-bool", "false"
        )

        # Disable automatic termination of inactive apps
        self.defaults_write(
            "NSGlobalDomain", "NSDisableAutomaticTermination", "-bool", "true"
        )

        # Disable Resume system-wide
        self.defaults_write(
            "com.apple.systempreferences", "NSQuitAlwaysKeepsWindows", "-bool", "false"
        )

    def configure_gatekeeper(self) -> None:
        """Configure Gatekeeper for specific applications."""

        alacritty_path = Path("/Applications/Alacritty.app")
        if alacritty_path.exists():
            subprocess.run(
                ["xattr", "-rd", "com.apple.quarantine", str(alacritty_path)],
                check=True,
            )

    def configure_pinentry(self) -> None:
        """Configure Pinentry preferences."""

        self.defaults_write("org.gpgtools.common", "UseKeychain", "-bool", "true")

    def get_configurators(self) -> Dict:
        """Return all configurators."""

        return {
            "Developer Mode": self.configure_developer_mode,
            "Power Manangement": self.configure_power_management,
            "System Settings": self.configure_system_settings,
            "Dock": self.configure_dock,
            "Activity Monitor": self.configure_activity_monitor,
            "Finder": self.configure_finder,
            "Screensaver": self.configure_screensaver,
            "Keyboard & Mouse": self.configure_keyboard_and_mouse,
            "UI/UX": self.configure_ui_ux,
            "Gatekeeper": self.configure_gatekeeper,
            "Pin Entry": self.configure_pinentry,
        }


def main() -> int:
    configurator = MacOSConfigurator()
    configurators = configurator.get_configurators()

    for name, config_fn in configurators.items():
        logger.info(f"Configuring {name}")
        try:
            config_fn()
        except subprocess.CalledProcessError as e:
            logger.error(f"Confuring {name} failed with exit code {e.returncode}")
            continue
        except Exception as e:
            logger.error(f"Error: {e}")
            return os.EX_SOFTWARE

    return os.EX_OK


if __name__ == "__main__":
    sys.exit(main())
