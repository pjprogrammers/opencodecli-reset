#!/usr/bin/env bash

set -e

# ==========================================
# 1. UNINSTALL OLD OPENCODE
# ==========================================

# Preview the files OpenCode's uninstaller will remove.
opencode uninstall --dry-run

# Uninstall the old OpenCode installation.
opencode uninstall


# ==========================================
# 2. REMOVE OLD GLOBAL NPM PACKAGE
# ==========================================

# Remove OpenCode v1's old npm package, if installed.
if npm list -g --depth=0 2>/dev/null | grep -q 'opencode-ai@'; then
    sudo npm uninstall -g opencode-ai
fi

# Clear Bash's cached executable paths.
hash -r


# ==========================================
# 3. REMOVE REMAINING USER DATA
# ==========================================

# Delete remaining OpenCode data, including saved
# credentials, sessions/history, configuration and state.
rm -rf \
    "$HOME/.local/share/opencode" \
    "$HOME/.config/opencode" \
    "$HOME/.local/state/opencode" \
    "$HOME/.cache/opencode"

# Remove npm debug logs containing references to opencode-ai.
find "$HOME/.npm/_logs" -maxdepth 1 -type f \
    -name '*-debug-0.log' \
    -exec grep -il 'opencode-ai' {} + 2>/dev/null |
while IFS= read -r log_file; do
    # Display the log being removed.
    printf 'Removing npm log: %s\n' "$log_file"

    # Delete the matching log.
    rm -f -- "$log_file"
done

# ==========================================
# 4. REMOVE ROOT'S SEPARATE INSTALLATION
# ==========================================

# Delete the root installation created accidentally.
# sudo is used only for this root-owned directory.
if sudo test -d /root/.opencode; then
    sudo rm -rf /root/.opencode
fi

# Remove its PATH entry from root's Bash configuration.
if sudo test -f /root/.bashrc; then
    sudo sed -i '\|/root/.opencode/bin|d' /root/.bashrc
fi


# ==========================================
# 5. REINSTALL OPENCODE V2
# ==========================================

# Install as your normal user, NOT as root.
curl -fsSL https://opencode.ai/v2/install | bash

# Reload the login shell to update PATH.
exec "$SHELL" -l
