# Agent brief: audit agent-memory files against the code

Same classification as `user-memory-prompt.md` (read it first; every rule there applies), with these
differences.

- Store: `/home/krit/nix/.claude/agent-memory/<agent-name>/`, git-tracked notes written by subagents
  (debugger, checker, researcher, test author...). Your files: `<FILE_LIST_PATH>` (paths relative to
  `/home/krit/nix`). Touch nothing outside `.claude/agent-memory/`.
- Each agent directory has a shared `MEMORY.md` index that is NOT yours (several batches may cover
  one directory). Report `INDEX:` lines for REWRITTEN files and `INDEX-REMOVE: <agent-dir>/<file>`
  for DELETED files; the orchestrator edits the indexes.
- These notes hold debugging lessons and reference recipes. A lesson about a mechanism, trap or tool
  that still exists in the code counts as having a counterpart (ACCURATE or REWRITTEN). A lesson
  about something fixed or removed is HISTORICAL. A tool/format recipe with no repo counterpart is RECIPE.
- `nix-test-author` lessons (`feedback_*`) are KEEP-RULE: verify only the repo facts they cite.
- Use the report shapes of the user-memory brief; prefix every file with its `<agent-dir>/`.
