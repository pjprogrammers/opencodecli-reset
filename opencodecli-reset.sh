```bash
#!/usr/bin/env bash

set -e

# ==========================================
# OPENCODE CLI RESET & REINSTALL UTILITY
# ==========================================
#
# Each operation has an independent Y/N prompt.
# Enter Y to execute an operation.
# Enter N to skip it and continue to the next step.
#
# Run as your normal Linux user, NOT as root.
#
# ==========================================


# ==========================================
# HELPER FUNCTION: YES / NO PROMPT
# ==========================================

# Displays a confirmation prompt for each operation.
# Accepts Y/y for Yes and N/n for No.
# Invalid input is requested again.

ask_yes_no() {
    local answer

    while true; do
        read -r -p "$1 [y/n]: " answer

        case "$answer" in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
            *)
                echo "Invalid input. Please enter y or n."
                ;;
        esac
    done
}


# ==========================================
# 1. UNINSTALL OLD OPENCODE
# ==========================================

echo
echo "=========================================="
echo "1. UNINSTALL OLD OPENCODE"
echo "=========================================="

if ask_yes_no "Do you want to uninstall the existing OpenCode installation?"; then

    # Check whether OpenCode is available before running its uninstaller.
    if command -v opencode >/dev/null 2>&1; then

        # Preview the files OpenCode's uninstaller intends to remove.
        opencode uninstall --dry-run

        # Ask for confirmation through OpenCode's own uninstaller.
        opencode uninstall

        # Remove the remaining executable if the uninstaller leaves it behind.
        rm -f "$HOME/.opencode/bin/opencode"

        # Remove the small launcher wrapper if present.
        rm -f "$HOME/.opencode/bin/opencode2"

    else
        echo "OpenCode command not found. Skipping uninstall."
    fi

else
    echo "Skipping OpenCode uninstall."
fi


# ==========================================
# 2. REMOVE OLD GLOBAL NPM PACKAGE
# ==========================================

echo
echo "=========================================="
echo "2. REMOVE OLD GLOBAL NPM PACKAGE"
echo "=========================================="

if ask_yes_no "Do you want to remove the old global opencode-ai npm package?"; then

    # Check whether npm is installed.
    if command -v npm >/dev/null 2>&1; then

        # Check whether opencode-ai exists in global npm packages.
        if npm list -g --depth=0 2>/dev/null | grep -q 'opencode-ai@'; then

            # Uninstall the legacy OpenCode npm package.
            sudo npm uninstall -g opencode-ai

        else
            echo "Global opencode-ai package not found."
        fi

    else
        echo "npm is not installed. Skipping npm cleanup."
    fi

else
    echo "Skipping global npm package removal."
fi

# Clear Bash's cached executable paths after package removal.
hash -r


# ==========================================
# 3. REMOVE REMAINING USER DATA AND LOGS
# ==========================================

echo
echo "=========================================="
echo "3. REMOVE USER DATA AND INSTALLATION"
echo "=========================================="

if ask_yes_no "Do you want to delete remaining OpenCode user data, configuration, cache, state and installation files?"; then

    # Remove OpenCode's remaining local data directories.
    # This can permanently delete saved authentication,
    # sessions, history, configuration and cached data.

    rm -rf \
        "$HOME/.local/share/opencode" \
        "$HOME/.config/opencode" \
        "$HOME/.local/state/opencode" \
        "$HOME/.cache/opencode"

    echo "Remaining OpenCode user data removed."

    # Remove the user's separate OpenCode installation directory.
    # HOME is dynamic, so this works for any normal Linux user.
    # It removes leftover binaries, wrappers and empty directories.

    if [ -d "$HOME/.opencode" ]; then

        rm -rf -- "$HOME/.opencode"

        echo "User OpenCode installation directory removed: $HOME/.opencode"

    else
        echo "User OpenCode installation directory not found."
    fi

else
    echo "Skipping user data and installation cleanup."
fi


# ==========================================
# 3B. REMOVE RELATED NPM DEBUG LOGS
# ==========================================

if ask_yes_no "Do you want to find and delete npm debug logs containing opencode-ai?"; then

    # Search npm's log directory for debug logs mentioning opencode-ai.
    # Only matching logs are deleted; unrelated npm logs are preserved.

    log_dir="$HOME/.npm/_logs"

    if [ -d "$log_dir" ]; then

        find "$log_dir" -maxdepth 1 -type f \
            -name '*-debug-0.log' \
            -exec grep -il 'opencode-ai' {} + 2>/dev/null |
        while IFS= read -r log_file; do

            # Display the name of each matching log.
            printf 'Removing npm log: %s\n' "$log_file"

            # Delete the matching log.
            rm -f -- "$log_file"

        done

        echo "Matching npm log cleanup completed."

    else
        echo "npm log directory not found."
    fi

else
    echo "Skipping npm log cleanup."
fi


# ==========================================
# 4. REMOVE ROOT OPENCODE INSTALLATION
# ==========================================

echo
echo "=========================================="
echo "4. REMOVE ROOT OPENCODE INSTALLATION"
echo "=========================================="

if ask_yes_no "Do you want to remove the separate OpenCode installation and references under /root?"; then

    # Check whether a root-owned OpenCode installation exists.
    if sudo test -d /root/.opencode; then

        # Remove the separate root installation.
        sudo rm -rf /root/.opencode

        echo "Root OpenCode installation removed."

    else
        echo "No root OpenCode installation found."
    fi

    # Clean root's Bash configuration if it exists.
    if sudo test -f /root/.bashrc; then

        # Remove the OpenCode installation PATH entry.
        sudo sed -i '\|/root/.opencode/bin|d' /root/.bashrc

        # Remove the standalone OpenCode comment.
        # This targets only a line containing exactly "# opencode".
        sudo sed -i '/^[[:space:]]*# opencode[[:space:]]*$/d' /root/.bashrc

        echo "Root Bash PATH entry and standalone OpenCode comment cleaned."

    else
        echo "Root .bashrc not found."
    fi

else
    echo "Skipping root installation cleanup."
fi


# ==========================================
# 5. REINSTALL OPENCODE V2
# ==========================================

echo
echo "=========================================="
echo "5. INSTALL / REINSTALL OPENCODE V2"
echo "=========================================="

if ask_yes_no "Do you want to install OpenCode v2 using the official installer?"; then

    # Ensure the installer runs as the normal user, not root.
    if [ "$EUID" -eq 0 ]; then
        echo "ERROR: Do not run the installer as root."
        echo "Exit root and run this script as your normal user."
        exit 1
    fi

    # Download and execute the official OpenCode v2 installer.
    curl -fsSL https://opencode.ai/v2/install | bash

    echo
    echo "OpenCode installation command completed."

else
    echo "Skipping OpenCode installation."
fi


# ==========================================
# 6. FINISH
# ==========================================

echo
echo "=========================================="
echo "RESET PROCESS FINISHED"
echo "=========================================="

# Reload the current login shell only if requested.
if ask_yes_no "Do you want to reload your shell now?"; then

    exec "$SHELL" -l

else
    echo "Shell reload skipped."
    echo "Run this manually when needed:"
    echo 'exec "$SHELL" -l'
fi
```
