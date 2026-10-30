# OpenCode Clean Reset

> **Use OpenCode CLI Unlimited for Free!**

> 🚀 **Hit your OpenCode Zen free-model limit? Switch API keys, reset your local OpenCode CLI, and get a fresh start!**
>
> Want to keep using free models? This utility automates a clean OpenCode reinstall so you can reconnect a different authorized API key without manually removing every configuration file.
>
> **The idea:** Clean up local OpenCode data → Reinstall OpenCode v2 → Connect another API key → Continue coding with available free models.
>
> ⚠️ **Important:** A local reset does not guarantee unlimited usage. OpenCode Zen may enforce server-side quotas, account restrictions, or rate limits. This utility does not bypass those limits.

A Bash utility to completely remove an existing OpenCode installation's local data and reinstall OpenCode v2 on Ubuntu and other compatible Linux distributions.

`opencode-clean-reset.sh` automates the cleanup and reinstallation process, including the removal of old configuration files, cached data, saved authentication, session history, and the legacy npm package.

## Features

- **Complete Local Reset** — Removes OpenCode's local configuration, data, cache, and state.
- **Legacy npm Cleanup** — Uninstalls the old globally installed `opencode-ai` npm package when detected.
- **Authentication Cleanup** — Removes locally stored OpenCode credentials as part of the reset.
- **Session & History Cleanup** — Deletes local OpenCode session and history data stored in the targeted directories.
- **Root Installation Cleanup** — Removes the separate `/root/.opencode` installation and its corresponding PATH entry from `/root/.bashrc`.
- **NPM Log Cleanup** — Deletes two specifically identified npm debug logs from the previous installation.
- **Fresh Installation** — Installs OpenCode v2 using the official installer.
- **Simple Workflow** — Combines the cleanup and reinstallation process in one script.
- **Free-Model Workflow** — Makes it easier to reconnect a different authorized API key after resetting local OpenCode data.

## Requirements

- Ubuntu or a compatible Linux distribution.
- Bash.
- `curl`.
- Node.js and npm if removing the legacy npm installation.
- `sudo` privileges for operations involving root-owned files.
- An internet connection.

## Installation

Clone the repository or download `opencode-clean-reset.sh`.

Make the script executable:

```bash
chmod +x opencode-clean-reset.sh
```

## Usage

Run the script as your normal Linux user:

```bash
./opencode-clean-reset.sh
```

**Do not run the script with `sudo` or as root.** It is designed to run under your regular user account and uses `sudo` only for the necessary root-owned cleanup operations.

The script performs the following operations:

1. Previews the files targeted by OpenCode's uninstaller.
2. Runs the OpenCode uninstall command.
3. Removes the legacy global `opencode-ai` npm package if detected.
4. Deletes remaining local OpenCode data, configuration, cache, and state.
5. Removes two specifically identified npm debug logs.
6. Removes the separate root installation and its PATH entry, if present.
7. Installs OpenCode v2 using the official installation script.
8. Reloads the current login shell.

Verify the installation:

```bash
opencode --version
```

Start OpenCode:

```bash
opencode
```

## What Gets Removed?

| Location | Purpose |
|---|---|
| `~/.local/share/opencode/` | Local application data, including session/history data and authentication where stored |
| `~/.config/opencode/` | Configuration files |
| `~/.local/state/opencode/` | Application state |
| `~/.cache/opencode/` | Cached files |
| Global npm `opencode-ai` package | Legacy npm installation |
| `~/.npm/_logs/` | Two explicitly specified npm debug logs |
| `/root/.opencode/` | Separate root-owned installation, if present |
| `/root/.bashrc` | Matching root OpenCode PATH entry |

The script does not intentionally delete your project directories, source code, Git repositories, or Yaply project.

**Important:** Review the script before running it. Deleting local data may permanently remove sessions, configuration, and saved credentials.

## Using OpenCode Zen Free Models

The purpose of this utility is to make a clean reinstall and API-key switch easier.

### Suggested workflow

1. Use OpenCode with an authorized OpenCode Zen API key.
2. If you encounter a local authentication or configuration issue, run the reset script.
3. Reinstall OpenCode v2.
4. Start OpenCode and use `/connect` where supported to authenticate with another authorized account or API key.
5. Select an available free model and test it.

### Can this provide unlimited free usage?

**Not guaranteed.** This script removes local files; it cannot reset quotas maintained by OpenCode Zen's servers.

Switching API keys may help when you need to change credentials or accounts, but it does not guarantee that usage limits will disappear. Free-model availability, quotas, and account restrictions remain subject to the provider's current policies.

Use only accounts and API keys you are authorized to use.

## Important Notes

### 1. The script is destructive

The cleanup commands permanently delete the targeted local OpenCode directories. Back up any configuration, credentials, or session history you want to retain.

### 2. npm logs are installation-specific

The script removes two npm logs identified during a previous troubleshooting session. These filenames are specific to that session and may not exist on another system.

### 3. OpenCode v2 installation

The script uses the official installer:

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

The installed version may change as the installer is updated.

### 4. Shell reload

The final command:

```bash
exec "$SHELL" -l
```

replaces the current shell with a new login shell. If the script is run from an environment where this is undesirable, verify the installation and reload the shell separately instead.

## Troubleshooting

**`opencode: command not found`**

Reload the login shell:

```bash
exec "$SHELL" -l
```

Then check:

```bash
command -v opencode
opencode --version
```

**Permission errors during npm cleanup**

The script uses `sudo` for the global npm uninstall when needed. If npm uses a custom installation prefix, the package may require a different removal procedure.

**Usage-limit errors persist after resetting**

A clean installation cannot remove limits enforced by OpenCode Zen's servers. Check the selected model, account status, provider usage limits, and any error details.

## License

Choose a license appropriate for your project before publishing this utility. If you want others to reuse, modify, and distribute it, consider adding an OSI-approved open-source license.

---

**OpenCode Clean Reset** — Clean up your local OpenCode CLI, reinstall, and reconnect. Less manual cleanup, more time coding.
