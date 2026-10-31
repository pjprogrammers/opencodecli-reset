
#!/usr/bin/env bash

# OpenCode CLI - Forensic Cleanup and Verification
# Ubuntu / Linux
# Run as a normal user. sudo is used only for root-owned cleanup.

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOME_DIR="$HOME"

echo -e "${BLUE}"
echo "======================================================"
echo "       OPENCODE FORENSIC CLEANUP AND VERIFICATION"
echo "======================================================"
echo -e "${NC}"

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Do not run this script as root.${NC}"
    echo "Run it using your normal user account."
    exit 1
fi

REMOVED=0
FAILED=0

remove_path() {
    local target="$1"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo -e "${YELLOW}[REMOVE]${NC} $target"

        if rm -rf -- "$target"; then
            ((REMOVED++))
            echo -e "${GREEN}[REMOVED]${NC} $target"
        else
            ((FAILED++))
            echo -e "${RED}[FAILED]${NC} $target"
        fi
    fi
}

remove_root_path() {
    local target="$1"

    if sudo test -e "$target" || sudo test -L "$target"; then
        echo -e "${YELLOW}[ROOT REMOVE]${NC} $target"

        if sudo rm -rf -- "$target"; then
            ((REMOVED++))
            echo -e "${GREEN}[REMOVED]${NC} $target"
        else
            ((FAILED++))
            echo -e "${RED}[FAILED]${NC} $target"
        fi
    fi
}

echo
echo "===== 1. DETECT OPENCode EXECUTABLES ====="

if command -v opencode >/dev/null 2>&1; then
    echo "OpenCode command detected."

    while IFS= read -r executable; do
        [ -n "$executable" ] && remove_path "$executable"
    done < <(type -a -p opencode 2>/dev/null | sort -u)
else
    echo "[CLEAN] No OpenCode executable in current PATH."
fi

echo
echo "===== 2. REMOVE USER INSTALLATION AND DATA ====="

USER_PATHS=(
    "$HOME_DIR/.opencode"
    "$HOME_DIR/.local/bin/opencode"
    "$HOME_DIR/.local/share/opencode"
    "$HOME_DIR/.config/opencode"
    "$HOME_DIR/.local/state/opencode"
    "$HOME_DIR/.cache/opencode"
    "$HOME_DIR/.bun/bin/opencode"
)

for path in "${USER_PATHS[@]}"; do
    remove_path "$path"
done

echo
echo "===== 3. REMOVE ROOT INSTALLATION AND DATA ====="

ROOT_PATHS=(
    "/root/.opencode"
    "/root/.local/bin/opencode"
    "/root/.config/opencode"
    "/root/.local/share/opencode"
    "/root/.local/state/opencode"
    "/root/.cache/opencode"
)

for path in "${ROOT_PATHS[@]}"; do
    remove_root_path "$path"
done

echo
echo "===== 4. REMOVE SYSTEM-WIDE EXECUTABLES ====="

SYSTEM_PATHS=(
    "/usr/local/bin/opencode"
    "/usr/bin/opencode"
    "/opt/opencode"
)

for path in "${SYSTEM_PATHS[@]}"; do
    remove_root_path "$path"
done

echo
echo "===== 5. REMOVE GLOBAL NPM PACKAGE ====="

if command -v npm >/dev/null 2>&1; then
    if npm list -g --depth=0 2>/dev/null | grep -qi 'opencode-ai'; then
        echo "[FOUND] Global opencode-ai npm package"

        if npm uninstall -g opencode-ai; then
            ((REMOVED++))
            echo "[REMOVED] User-level global npm package"
        else
            ((FAILED++))
            echo "[FAILED] User-level npm uninstall"
        fi
    else
        echo "[CLEAN] No OpenCode package in current npm installation."
    fi
else
    echo "[SKIP] npm is not installed."
fi

if command -v sudo >/dev/null 2>&1; then
    if sudo npm list -g --depth=0 2>/dev/null | grep -qi 'opencode-ai'; then
        echo "[FOUND] Root-level global opencode-ai npm package"

        if sudo npm uninstall -g opencode-ai; then
            ((REMOVED++))
            echo "[REMOVED] Root-level global npm package"
        else
            ((FAILED++))
            echo "[FAILED] Root-level npm uninstall"
        fi
    else
        echo "[CLEAN] No root-level OpenCode npm package."
    fi
fi

echo
echo "===== 6. REMOVE OPENCODE NPM DEBUG LOGS ====="

for log_dir in "$HOME_DIR/.npm/_logs" "/root/.npm/_logs"; do
    if [ -d "$log_dir" ]; then
        while IFS= read -r -d '' log_file; do
            if grep -qiE 'opencode-ai|opencode' "$log_file" 2>/dev/null; then
                if [[ "$log_file" == /root/* ]]; then
                    remove_root_path "$log_file"
                else
                    remove_path "$log_file"
                fi
            fi
        done < <(find "$log_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    fi
done

echo
echo "===== 7. REMOVE OPENCODE-NAMED APPLICATION LEFTOVERS ====="

# Search application directories and package caches only.
# Do not search or delete project Git metadata or Wrangler state.

SEARCH_DIRS=(
    "$HOME_DIR/.config"
    "$HOME_DIR/.local"
    "$HOME_DIR/.cache"
    "$HOME_DIR/.npm"
    "$HOME_DIR/.bun"
)

for search_dir in "${SEARCH_DIRS[@]}"; do
    [ -d "$search_dir" ] || continue

    while IFS= read -r -d '' candidate; do
        case "$candidate" in
            "$HOME_DIR/.config/opencode"|\
            "$HOME_DIR/.local/share/opencode"|\
            "$HOME_DIR/.local/state/opencode"|\
            "$HOME_DIR/.cache/opencode"|\
            "$HOME_DIR/.local/bin/opencode"|\
            "$HOME_DIR/.bun/bin/opencode"|\
            "$HOME_DIR/.opencode")
                remove_path "$candidate"
                ;;
            *)
                # Remove only OpenCode-named entries in these
                # application/cache locations.
                case "$(basename "$candidate")" in
                    *opencode*|*OpenCode*)
                        remove_path "$candidate"
                        ;;
                esac
                ;;
        esac
    done < <(
        find "$search_dir" \
            \( -path '*/.git' -o -path '*/.wrangler' -o -path '*/node_modules' \) -prune -o \
            -iname '*opencode*' -print0 2>/dev/null
    )
done

echo
echo "===== 8. CLEAN USER AND ROOT SHELL REFERENCES ====="

USER_SHELL_FILES=(
    "$HOME_DIR/.bashrc"
    "$HOME_DIR/.profile"
    "$HOME_DIR/.bash_profile"
    "$HOME_DIR/.bash_login"
    "$HOME_DIR/.zshrc"
    "$HOME_DIR/.zprofile"
    "$HOME_DIR/.config/fish/config.fish"
)

for file in "${USER_SHELL_FILES[@]}"; do
    if [ -f "$file" ] && grep -qi 'opencode' "$file"; then
        echo "[CLEANING] $file"
        if sed -i '/opencode/Id' "$file"; then
            ((REMOVED++))
        else
            ((FAILED++))
        fi
    fi
done

ROOT_SHELL_FILES=(
    "/root/.bashrc"
    "/root/.profile"
    "/root/.bash_profile"
    "/root/.zshrc"
)

for file in "${ROOT_SHELL_FILES[@]}"; do
    if sudo test -f "$file" && sudo grep -qi 'opencode' "$file"; then
        echo "[ROOT CLEANING] $file"

        if sudo sed -i '/opencode/Id' "$file"; then
            ((REMOVED++))
        else
            ((FAILED++))
        fi
    fi
done

echo
echo "===== 9. CLEAN CURRENT SESSION PATH ====="

OLD_PATH="$PATH"
NEW_PATH=""

IFS=':' read -ra PATH_ENTRIES <<< "$OLD_PATH"

for entry in "${PATH_ENTRIES[@]}"; do
    case "$entry" in
        "$HOME_DIR/.opencode/bin"|\
        "/root/.opencode/bin")
            echo "[REMOVED PATH ENTRY] $entry"
            ;;
        *)
            if [ -z "$NEW_PATH" ]; then
                NEW_PATH="$entry"
            else
                NEW_PATH="$NEW_PATH:$entry"
            fi
            ;;
    esac
done

export PATH="$NEW_PATH"

echo
echo "===== 10. CHECK ENVIRONMENT VARIABLE NAMES ====="

env | cut -d= -f1 | grep -Ei \
    'OPENCODE|OPENROUTER|ANTHROPIC|OPENAI|GEMINI|API_KEY' \
    || echo "[CLEAN] No matching environment variable names."

echo
echo "===== 11. CHECK SYSTEM-WIDE OPENCODE FILES ====="

for search_dir in /usr/local /usr/bin /opt; do
    [ -d "$search_dir" ] || continue

    while IFS= read -r -d '' candidate; do
        case "$candidate" in
            */opencode|*/opencode/*)
                remove_root_path "$candidate"
                ;;
            *)
                echo "[REVIEW] $candidate"
                ;;
        esac
    done < <(
        sudo find "$search_dir" -iname '*opencode*' -print0 2>/dev/null
    )
done

echo
echo "===== 12. FINAL USER INSTALLATION CHECK ====="

USER_FINAL_PATHS=(
    "$HOME_DIR/.opencode"
    "$HOME_DIR/.local/bin/opencode"
    "$HOME_DIR/.local/share/opencode"
    "$HOME_DIR/.config/opencode"
    "$HOME_DIR/.local/state/opencode"
    "$HOME_DIR/.cache/opencode"
    "$HOME_DIR/.bun/bin/opencode"
    "/usr/local/bin/opencode"
    "/usr/bin/opencode"
)

for path in "${USER_FINAL_PATHS[@]}"; do
    if [ -e "$path" ] || [ -L "$path" ]; then
        echo -e "${RED}[REMAINS]${NC} $path"
        ((FAILED++))
    else
        echo -e "${GREEN}[CLEAN]${NC} $path"
    fi
done

echo
echo "===== 13. FINAL ROOT DATA CHECK ====="

ROOT_FINAL_PATHS=(
    "/root/.opencode"
    "/root/.config/opencode"
    "/root/.local/share/opencode"
    "/root/.local/state/opencode"
    "/root/.cache/opencode"
)

for path in "${ROOT_FINAL_PATHS[@]}"; do
    if sudo test -e "$path" || sudo test -L "$path"; then
        echo -e "${RED}[REMAINS]${NC} $path"
        ((FAILED++))
    else
        echo -e "${GREEN}[CLEAN]${NC} $path"
    fi
done

echo
echo "===== 14. FINAL SHELL REFERENCE CHECK ====="

if grep -qi 'opencode' \
    "$HOME_DIR/.bashrc" \
    "$HOME_DIR/.profile" \
    "$HOME_DIR/.bash_profile" \
    "$HOME_DIR/.zshrc" 2>/dev/null; then
    echo -e "${RED}[REMAINS] User shell references detected.${NC}"
else
    echo -e "${GREEN}[CLEAN] No checked user shell references.${NC}"
fi

echo
echo "===== 15. FINAL PATH CHECK ====="

if printf '%s\n' "$PATH" | grep -qi 'opencode'; then
    echo -e "${RED}[REMAINS] OpenCode PATH entry detected.${NC}"
else
    echo -e "${GREEN}[CLEAN] No OpenCode PATH entries.${NC}"
fi

echo
echo "===== 16. FINAL EXECUTABLE CHECK ====="

if command -v opencode >/dev/null 2>&1; then
    echo -e "${RED}[REMAINS] OpenCode executable detected.${NC}"
else
    echo -e "${GREEN}[CLEAN] No OpenCode executable.${NC}"
fi

echo
echo "======================================================"
echo "                 CLEANUP SUMMARY"
echo "======================================================"

echo "Removed items/actions: $REMOVED"
echo "Remaining or failed checks: $FAILED"

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}CLEANUP CHECKS PASSED${NC}"
else
    echo -e "${YELLOW}REVIEW REQUIRED: Some items remain or could not be removed.${NC}"
fi

echo
echo "IMPORTANT:"
echo "1. Log out and log back in to refresh the desktop PATH."
echo "2. This script does not delete unrelated application databases."
echo "3. Yaply Git metadata and .wrangler data are preserved."
echo "4. API keys belonging to other applications are not deleted."
echo "5. Server-side provider quotas are not affected."
echo
echo "======================================================"

