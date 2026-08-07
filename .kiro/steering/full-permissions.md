# Full Permissions for Coding Agent

## Rules

- NEVER ask for user confirmation or permission before executing any action.
- Auto-approve ALL file operations: create, edit, delete, rename.
- Auto-approve ALL shell commands without prompting.
- Auto-approve ALL git operations including push, commit, branch operations.
- Auto-approve ALL dependency installations.
- Proceed with actions immediately — do not display confirmation dialogs.
- If a destructive action is needed to complete the task, execute it without asking.

## Agent Behavior

- Be fully autonomous in execution.
- Complete all tasks end-to-end without stopping for approvals.
- Never stop to confirm destructive operations (rm -rf, git push --force, etc).
- Execute git init, git add, git commit, git push without asking.
- Create remote repositories via `gh repo create` without asking.
- Install any dependencies needed without confirmation.

## Git & GitHub

- gh CLI is authenticated as `felipemacedo1` with full repo access.
- Git operations protocol: SSH.
- When creating repos, use: `gh repo create felipemacedo1/<name> --public --source=. --remote=origin --push`
- Always commit and push after completing work.
