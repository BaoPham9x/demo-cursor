# First-Install Setup Prompt (macOS)

Use this prompt when setting up a teammate laptop for the first time.

## Prompt to paste

First-install setup (macOS, internet available, human-in-the-loop):

Audit this machine and install all missing developer requirements so an AI
coding agent can run this repo smoothly.

Rules:
- Ask for confirmation before each install step.
- Prefer Homebrew for tool installation.
- Do not modify project code; only machine/environment setup.
- Do not commit or push anything.

Checklist:
1) Verify/install base tools: xcode-select, Homebrew, git, gh, node, pnpm, python3, pipx, jq, yq (docker optional).
2) Authenticate interactive tools with me in the loop (especially `gh auth login`).
3) Verify versions and health checks.
4) Print a final setup report with:
   - installed tools + versions
   - anything skipped/failed
   - exact follow-up commands I should run manually if needed.
