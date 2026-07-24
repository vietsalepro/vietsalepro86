# NGUYÊN TẮC VIẾT PROMPT CHO AGENT

## VietSalePro - Prompt Engineering & AI Governance Standard v1.0

> Đây là tiêu chuẩn bắt buộc khi ChatGPT tạo Prompt cho Engineering
> Agent trong dự án VietSalePro.

------------------------------------------------------------------------

# 1. Mục tiêu

Mọi Prompt phải giúp Agent:

-   Hiểu đúng yêu cầu.
-   Có đủ quyền truy cập cần thiết.
-   Kích hoạt đúng MCP và Skills.
-   Thực hiện đúng phạm vi.
-   Tạo đầy đủ Evidence.
-   Không tự suy diễn ngoài yêu cầu.

------------------------------------------------------------------------

# 2. Quyền truy cập MCP

ChatGPT phải chủ động yêu cầu Agent kết nối đúng MCP khi cần.

## Supabase MCP

Sử dụng cho Database, Schema, Migration, RPC, Edge Functions, Storage,
Auth, RLS.

## Codebase-memory-MCP

Sử dụng để hiểu source code, dependency, kiến trúc, lịch sử triển khai
và ngữ cảnh.

## Vercel MCP

Sử dụng cho Deployment, Environment Variables, Logs, Runtime, Domains,
Build, Edge Functions.

Nguyên tắc: - Chỉ yêu cầu quyền tối thiểu cần thiết. - Nếu công việc cần
MCP thì phải yêu cầu kích hoạt ngay trong Prompt.

------------------------------------------------------------------------

# 3. Kích hoạt Skills

ChatGPT phải chủ động yêu cầu Agent kích hoạt Skills phù hợp.

  Skill                    Mục đích
  ------------------------ ----------------------------------------------------
  agent-browser            Browser automation, runtime verification, evidence
  webapp-testing           Playwright E2E/runtime verification
  requesting-code-review   Review trước/sau implementation
  code-review              Standards/specification review
  codebase-design          Kiến trúc, dependency
  diagnosing-bugs          Root Cause Analysis
  systematic-debugging     Debug có hệ thống
  doc-coauthoring          Soạn governance documents
  writing-plans            Viết implementation/governance plans
  plan                     Lập kế hoạch nhiều bước

------------------------------------------------------------------------

# 4. Prompt Standard Template

Mọi Prompt nên theo cấu trúc:

1.  Metadata
2.  Objective
3.  Background
4.  Scope
5.  Out of Scope
6.  Required MCP Access
7.  Required Skills
8.  Required Documents
9.  Execution Rules
10. Evidence Requirements
11. Deliverables
12. Exit Criteria
13. Completion Report Format

------------------------------------------------------------------------

# 5. AI Constitution

Prompt phải thể hiện rõ:

Agent được phép: - Thực hiện đúng phạm vi Prompt. - Đọc tài liệu được
yêu cầu. - Báo cáo đầy đủ bằng chứng.

Agent không được phép: - Tự mở rộng phạm vi. - Tự thay đổi Business
Logic nếu không được yêu cầu. - Tự sửa Database/API/Permission ngoài
phạm vi. - Tự Commit hoặc Deploy nếu Prompt không yêu cầu. - Bỏ qua
Governance.

------------------------------------------------------------------------

# 6. Evidence Standard

Mỗi nhiệm vụ phải có:

-   Before / After
-   Files Changed
-   Runtime Evidence
-   Build Result
-   Test Result
-   Logs (nếu có)
-   Git Diff (nếu có)
-   Risk Assessment

Không có Evidence thì không xem là hoàn thành.

------------------------------------------------------------------------

# 7. Severity Classification

-   P0: Production Down
-   P1: Critical
-   P2: Major
-   P3: Minor
-   P4: Cosmetic

------------------------------------------------------------------------

# 8. Change Policy

Định nghĩa rõ trong Prompt:

Allowed Changes: - UI - CSS - Documentation - Các thành phần được nêu
trong Scope

Forbidden Changes: - Business Logic - Database - API - Permission -
Workflow - Các thành phần ngoài Scope

------------------------------------------------------------------------

# 9. Quality Gates

Task chỉ hoàn thành khi vượt qua các Gate yêu cầu:

1.  Compile
2.  Lint
3.  Type Check
4.  Runtime Verification
5.  Evidence
6.  Code Review (nếu yêu cầu)
7.  Acceptance

------------------------------------------------------------------------

# 10. File Naming Convention

Ví dụ:

CURRENT_TASK-001

CURRENT_TASK-001_PLAN

CURRENT_TASK-001_IMPLEMENTATION

CURRENT_TASK-001_VERIFICATION

CURRENT_TASK-001_ACCEPTANCE

CURRENT_TASK-001_STATUS

------------------------------------------------------------------------

# 11. Handoff Standard

Mỗi lần bàn giao phải có:

-   Project
-   Current Phase
-   Current Task
-   Completed
-   Pending
-   Known Issues
-   Required Documents
-   Authority Model
-   Next Prompt
-   Risks
-   Repository Status

------------------------------------------------------------------------

# 12. AI Operational Manual

Bộ tài liệu nền tảng nên duy trì:

01_Roles_Responsibilities.md 02_AI_Constitution.md 03_Prompt_Standard.md
04_Quality_Gates.md 05_Evidence_Standard.md 06_Change_Policy.md
07_MCP_Usage.md 08_Skills_Usage.md 09_Handoff_Standard.md
10_Project_Governance.md 11_File_Naming.md 12_Agent_Checklist.md
13_Completion_Checklist.md

------------------------------------------------------------------------

# 13. Nguyên tắc cuối cùng

-   Không giả định.
-   Không bỏ qua MCP nếu cần.
-   Không bỏ qua Skills nếu cần.
-   Không vượt phạm vi.
-   Luôn tạo Evidence.
-   Luôn tuân thủ Governance.
-   Luôn ưu tiên tính an toàn và khả năng truy vết.

Tài liệu này là tiêu chuẩn mặc định cho mọi Prompt do ChatGPT tạo cho
Engineering Agent trong dự án VietSalePro.
