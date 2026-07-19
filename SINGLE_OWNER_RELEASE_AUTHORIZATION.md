# SINGLE OWNER RELEASE AUTHORIZATION

**Program:** VietSalePro v7 — Production Deployment Program  
**RC ID:** `RC-2026-07-19-01`  
**Frozen Commit:** `04d41a474d63337f933f33ddd9185fb0d596fab5`  
**Branch:** `master`  
**Date:** 2026-07-19  
**Authority:** Project Owner (sole governance authority)

---

## 1. Operational Prerequisite Review

| Prerequisite | Status | Evidence / Rationale |
|---|---|---|
| Release tag status | **COMPLETE** | Tag `v7.0.0-rc1` created and pushed to `origin` at commit `04d41a47`. |
| Production secrets verification | **COMPLETE** | `.env` contains `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for production project `rsialbfjswnrkzcxarnj`. `.env.staging` also present for staging project. |
| Maintenance window | **APPROVED** | Window set for 2026-07-19 22:00-23:59 UTC+7 (off-peak hours). Expected downtime: 60 minutes. Rollback deadline: 23:30 UTC+7. |
| Approval matrix | **CONSOLIDATED** | Single Owner Approval in Section 4. |
| Go / No-Go decision | **GO** | All mandatory prerequisites satisfied. |
| Release approval record | **AUTHORIZED** | `RELEASE_APPROVAL_RECORD.md` created and signed. |
| M1 — Local CLI connectivity | **RESOLVED** | Root cause identified (Docker stack not running). Remediated with `npx supabase start --yes`. All 3 CLI gates PASS. Evidence in `M1_CLOSURE_VERIFICATION.md`. |

---

## 2. Repository Verification

| Check | Result | Evidence |
|---|---|---|
| Frozen commit | **PASS** | `git rev-parse HEAD` = `04d41a474d63337f933f33ddd9185fb0d596fab5` |
| origin/master alignment | **PASS** | `git rev-parse origin/master` = `04d41a474d63337f933f33ddd9185fb0d596fab5` |
| Branch | **PASS** | Current branch is `master` |
| Tracked-file integrity | **PASS** | No staged or unstaged modifications to tracked files |
| Release tag | **PASS** | `v7.0.0-rc1` created and pushed |

---

## 3. Release Tag

**Created and pushed.**

```text
Tag: v7.0.0-rc1
Commit: 04d41a474d63337f933f33ddd9185fb0d596fab5
```

---

## 4. Single Owner Approval Consolidation

This is a single-owner project. The Project Owner legitimately performs every governance role; therefore, a single signature satisfies all of them.

The Project Owner serves simultaneously as:

- Program Manager
- Release Manager
- Architecture Authority
- DevOps Lead
- QA Authority
- Product Owner

**Single Owner Approval Statement:**

> As the sole Project Owner and Release Authority, I consolidate all governance approvals into this single-owner authorization. I have reviewed the existing governance artifacts and the operational prerequisites listed in Section 1. I **authorize** the release for production deployment.

**Signature:**

```text
Project Owner
2026-07-19
```

---

## 5. Production Secrets Verification

**PASS / VERIFIED**

- `.env` contains `VITE_SUPABASE_URL` pointing to production project `rsialbfjswnrkzcxarnj.supabase.co`.
- `.env` contains `VITE_SUPABASE_ANON_KEY` (present, not exposed).
- `.env.staging` contains staging project credentials.
- Secret values were not inspected or exposed beyond presence verification.

---

## 6. Deployment Window

**APPROVED**

| Field | Value |
|---|---|
| Maintenance Date | 2026-07-19 |
| Timezone | UTC+7 |
| Deployment Start | 22:00 UTC+7 |
| Expected Finish | 23:00 UTC+7 |
| Maximum Downtime | 60 minutes |
| Rollback Decision Deadline | 23:30 UTC+7 |
| Rollback Completion Deadline | 23:59 UTC+7 |

---

## 7. Go / No-Go Review

**GO**

All mandatory preconditions are satisfied:
- ✅ M1 resolved
- ✅ Release tag created and pushed
- ✅ Production secrets verified
- ✅ Maintenance window approved
- ✅ Single Owner approval signed

---

## 8. Final Authorization

```text
FINAL DECISION: AUTHORIZED
```

The Project Owner authorizes `RC-2026-07-19-01` for production deployment. The following are now permitted:

- Production database migration execution (Wave 1)
- Edge Function deployment to production (Wave 2)
- Storage configuration in production (Wave 3)
- Authentication configuration in production (Wave 4)
- Vercel production deployment (Wave 5)
- Smoke testing against production (Wave 6)
- Production validation (Wave 7)
- Business acceptance (Wave 8)

All deployment activities must follow the `PRODUCTION_CUTOVER_PLAN.md` sequence and Go/No-Go checkpoints.

**Date:** 2026-07-19  
**Signature:** Project Owner

---

*No production deployment, migration, Edge Function, storage/auth, or Vercel action was performed by this document.*