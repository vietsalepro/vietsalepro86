# VietSalePro — Codebase Memory Repository Policy

> **Date**: 2026-07-24
> **Authority**: Production Owner

## 1. Purpose

Define how `.codebase-memory` is treated during repository inspection, finalization, and acceptance.

## 2. Inspection Policy

- `.codebase-memory/` is a generated AI Workspace and is excluded from routine source inspections.
- During transition, any tracked or modified `.codebase-memory` file is logged as a governance exception, not a source-code defect.
- `git status` and `git diff` outputs that include `.codebase-memory` are reviewed by the Production Owner or Chief Technical Advisor, not by automated source-quality gates.
- `search_graph`, `query_graph`, and `trace_path` may be used to inspect the knowledge graph without altering Git state.

## 3. Finalization Policy

- A repository finalization package must not contain `.codebase-memory` generated artifacts.
- If `.codebase-memory` files are modified or untracked at finalization time, finalization is `BLOCKED` until one of the following is true:
  1. The files are ignored by `.gitignore` and not staged.
  2. The files are reverted to the committed state.
  3. The Production Owner explicitly authorizes a curated relocation of the markdown baselines.
- `graph.db.zst`, `artifact.json`, and `update-codebase-memory.txt` are never eligible for finalization.

## 4. Acceptance Policy

- Wave acceptance, deployment readiness, and governance review are not blocked by the existence of `.codebase-memory` files in the working tree, provided the Git policy is documented and the files are either ignored or explicitly relocated.
- A final `CODEBASE MEMORY GOVERNANCE BASELINE COMPLETED` state requires the Git policy to be defined; it does not require immediate Git implementation.

## 5. No-Change Guardrails

This policy program does not modify:

- Business Logic
- UI / CSS
- Database / RPC / Edge Functions
- Deployments
- `.gitignore`
- Tracked files

## 6. Exception Authority

Only the Production Owner may override this policy. All overrides are recorded in the governance decision register.
