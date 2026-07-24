# PHASE_02_CODEBASE_MEMORY_VALIDATION

## Program

VietSalePro -- Codebase Memory Validation

### Objective

Validate completeness, consistency and coverage of the existing Codebase
Memory.

Reuse the existing Codebase Memory as the primary source.

Do not rebuild the knowledge base unless a missing or inconsistent area
is detected.

Only inspect additional repository content when necessary to validate or
complete the existing knowledge.

## Required MCP

-   Mandatory: Codebase-memory-MCP
-   Read-only: Supabase MCP, Vercel MCP

## Required Skills

-   codebase-design
-   diagnosing-bugs
-   systematic-debugging
-   doc-coauthoring
-   requesting-code-review

## Execution Mode

READ ONLY. No implementation, commit, deploy or database changes.

## Validation Scope

Verify coverage of: - Project structure - Architecture - Business
domains - Business logic - Database - Migration history - RPC - Edge
Functions - Permissions - Routing - Services - UI - State management -
Environment - Testing - Governance - Documentation - Handoff documents

## Cross Validation

Cross-check: Repository ↓ Indexed Knowledge ↓ Supabase Metadata ↓
Migration History ↓ Governance Documents ↓ Edge Functions ↓ Runtime
Configuration

## Detect

Identify: - Missing modules - Missing services - Missing tables -
Missing RPCs - Missing Edge Functions - Missing migrations - Missing
documentation - Broken relationships - Duplicate or contradictory
understanding - Coverage gaps - Knowledge ambiguity

## Required Report

Include: - Overall coverage - Business coverage - Database coverage -
RPC coverage - Edge Function coverage - Migration coverage -
Documentation coverage - Architecture coverage - Confidence score -
Risks - Recommendations to improve knowledge quality (not source code)

## Exit Criteria

Codebase Memory is a trusted semantic source for future implementation
and planning. No source code is modified.
