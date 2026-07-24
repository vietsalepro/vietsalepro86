# Codebase Memory Git Migration — Repository State Before

**Date**: 2026-07-24
**Branch**: master
**HEAD**: 11c989dfcd92e487f8fd428c2f390be7d477dc3f

## `git status --short`

```
 M .codebase-memory/artifact.json
 M .codebase-memory/graph.db.zst
?? .codebase-memory/CODEBASE_MEMORY_BASELINE.md
?? .codebase-memory/SEMANTIC_MEMORY.md
?? .codebase-memory/VALIDATION_REPORT.md
?? .codebase-memory/update-codebase-memory.txt
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_BASELINE_ACCEPTANCE_REVIEW.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_CONFIGURATION_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_ENGINEERING_STANDARD.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_FINAL_STATE.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_GOVERNANCE_BASELINE.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_GOVERNANCE_DECISION_RECORD.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_GIT_POLICY.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_PROGRAM_FINAL_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_PROMPT_STANDARD.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_RELOCATION_AUDIT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_RELOCATION_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_REPOSITORY_POLICY.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_SUPPORTED_CONFIGURATION.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_WORKSPACE_VERIFICATION.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_COMMIT_ARTIFACT_INVENTORY.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_COMMIT_AUDIT_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_COMMIT_EXECUTION_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_COMMIT_VERIFICATION_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_POST_COMMIT_GOVERNANCE_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_REPOSITORY_BASELINE_COMMIT_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_REPOSITORY_FINALIZATION_REPORT.md
?? ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-01_REPOSITORY_STATE_AFTER_COMMIT.md
 M package-lock.json
 M package.json
```

> Note: `git status` also emitted a line-level warning that `.codebase-memory/artifact.json` LF will be replaced by CRLF the next time Git touches it.

## `git diff --stat`

```
 .codebase-memory/artifact.json |  14 ++++-----
 .codebase-memory/graph.db.zst  | Bin 5475929 -> 7802519 bytes
 package-lock.json              |  65 +++++++++++++++++++++++++++++++++++++++++
 package.json                   |   2 ++
 4 files changed, 74 insertions(+), 7 deletions(-)
```

## Tracked `.codebase-memory` files

```
.codebase-memory/.gitattributes
.codebase-memory/artifact.json
.codebase-memory/graph.db.zst
memory-zone/.codebase-memory/.gitattributes
memory-zone/.codebase-memory/_config.db
memory-zone/.codebase-memory/artifact.json
```

## `.gitignore` Codebase Memory rule

Not present.
