# Pre-Reading — Day 3: AI-Powered IaC & Pipeline Engineering

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 35-45 phút.
> Mục tiêu: hiểu cách dùng AI sinh IaC/pipeline an toàn, không rơi vào bẫy "vibe-coding".

---

## Mục lục

1. [Bối cảnh: IaC gặp AI](#1-bối-cảnh)
2. [Concept: từ "as code" đến "as intention"](#2-concept)
3. [Core Components của AI-Powered IaC workflow](#3-core-components)
4. [Rủi ro lớn nhất: AI sinh "code có vẻ đúng"](#4-rủi-ro)
5. [3-Layer Defense — kiến trúc an toàn](#5-3-layer-defense)
6. [Features: prompt patterns & công cụ](#6-features)
7. [Implementation: pipeline-as-code với AI](#7-implementation)
8. [Best Practices](#8-best-practices)
9. [Case Study](#9-case-study)
10. [Thuật ngữ & Đọc thêm](#10-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. IaC vẫn là nền tảng — nhưng đang phức tạp lên

Terraform tiếp tục thống trị IaC năm 2026. Nhưng viết, review, bảo trì codebase Terraform lớn ngày càng tốn thời gian. Đây là nơi AI bước vào.

### 1.2. Một con số biết nói

Một SaaS lớn báo cáo: **30% IaC của họ giờ do AI sinh** — nhưng họ cũng thấy **gấp 3 lần lỗi cấu hình** trong CI/CD so với năm trước: sai secret, mở port, sai S3 policy, API không bảo vệ.

→ AI tăng tốc, nhưng nếu thiếu kiểm soát, nó tạo ra **security debt** mới.

### 1.3. Ngữ cảnh hệ sinh thái 2026

- **OpenTofu vs Terraform** — OpenTofu là fork (do thay đổi license BSL của HashiCorp 2023), nay thuộc Linux Foundation. Cú pháp HCL gần như tương thích.
- **PR-driven workflow là chuẩn** — `terraform apply` từ laptop là anti-pattern. Atlantis (open-source) / Spacelift chạy `plan` trên mỗi PR, `apply` qua approval gate.
- **Boundary Terraform ↔ Kubernetes** — Terraform cho infra mà K8s chạy trên đó (VPC, node group, IAM, managed DB); công cụ K8s-native (Crossplane, ACK) cho resource *bên trong* cluster. Trộn lẫn cùng resource type → drift.

---

## 2. Concept

### 2.1. Từ "Infrastructure as Code" sang "Infrastructure as Intention"

| Thời kỳ | Cách làm |
|---|---|
| **IaC truyền thống** | Copy snippet từ docs, sửa biến, hy vọng `plan` chạy sạch |
| **AI-Powered IaC** | Mô tả **ý định** (intent) bằng ngôn ngữ tự nhiên, AI sinh HCL; người review |

Tương lai của infrastructure không chỉ "as code" — đang trở thành "as intention".

### 2.2. Spec-driven development

Thay vì gõ Terraform từng dòng, ta viết một **spec**: mô tả yêu cầu + ràng buộc + tiêu chí chấp nhận. AI sinh code từ spec. Spec rõ ràng = output chất lượng.

Có 2 "mode" làm việc với AI cho IaC:
- **Vibe mode** — prompt tự do, nhanh, hợp exploration. Rủi ro cao nếu apply thẳng.
- **Spec mode** — viết spec có cấu trúc (user story, acceptance criteria) trước, AI sinh theo. An toàn hơn cho production.

### 2.3. AI giỏi gì và KHÔNG giỏi gì với IaC

| AI giỏi | AI KHÔNG giỏi |
|---|---|
| Sinh boilerplate (variable, tfvars) | Hiểu ý định kinh doanh của tổ chức |
| Convert (shell → Ansible, scaffolding Pulumi) | Tự biết tagging policy, naming convention nội bộ |
| Giải thích `plan` output bằng tiếng người | Đảm bảo tuân thủ compliance nếu không được nêu |
| Lặp nhanh: viết → test → log → verify | Thay thế phán đoán kỹ thuật của con người |

---

## 3. Core Components của AI-Powered IaC workflow

| Thành phần | Vai trò |
|---|---|
| **AI coding agent** | Sinh HCL, chạy CLI, lặp. Claude Code, Cursor, Copilot |
| **Terraform MCP server** | Cho agent query registry, schema provider — giảm hallucination |
| **Linter** (`tflint`) | Kiểm cú pháp, naming, deprecated argument |
| **Security scanner** (`checkov`, `tfsec`) | Quét misconfiguration — policy-as-code |
| **Policy engine** (OPA/Rego, Sentinel) | Enforce rule tổ chức: block `apply` nếu vi phạm |
| **Cost estimator** (`infracost`) | Ước tính chi phí trước khi apply |
| **PR-driven orchestrator** (Atlantis/Spacelift) | `plan` trên PR, `apply` qua approval |

**Nguyên tắc:** AI augment workflow hiện có, KHÔNG thay thế. Bạn vẫn nắm quyết định quan trọng; AI lo phân tích và sinh code lặp đi lặp lại.

---

## 4. Rủi ro lớn nhất — AI sinh "code có vẻ đúng"

### 4.1. Vấn đề không phải code xấu — mà là code "plausible"

> Vấn đề không phải AI sinh code *tệ*. Vấn đề là nó sinh code *trông có vẻ đúng* (plausible) — code mà người ta không còn đọc từng dòng.

Một module Terraform 200 dòng do AI sinh trong 30 giây: network rule, IAM policy, storage config. Developer xem cấu trúc, không thấy lỗi cú pháp, chạy `terraform apply`. Cái họ **không** kiểm tra:
- Security group có ingress `0.0.0.0/0` không?
- S3 bucket policy có chặn public access không?
- RDS có bật encryption-at-rest không?

Thời gian sinh trung bình: 30 giây. Thời gian review trung bình: **dưới 60 giây**. Tốc độ trở thành lỗ hổng bảo mật khi review biến thành "tick ô cho xong".

### 4.2. Mất mental model

Khi team ngừng viết HCL bằng tay, họ dần **mất mô hình tư duy** về chính hạ tầng của mình. Bài test nhanh: nhờ một thành viên giải thích module AI-sinh *từng dòng* mà không mở docs. Nếu >20% không giải thích được → khoảng cách nguy hiểm.

### 4.3. Vibe-coding IaC vào production — anti-pattern

```
AI sinh Terraform  →  apply thẳng  →  💥
(không review, không scan, không policy gate)
```

---

## 5. 3-Layer Defense — kiến trúc an toàn

Đây là pattern cốt lõi của Day 3.

```
┌─ Lớp 1: AI GENERATE ──────────────────────────────────┐
│  Claude Code + Terraform MCP sinh module               │
│  Prompt theo pattern: constraint-first, security-first │
└────────────────────────────────────────────────────────┘
                          ↓
┌─ Lớp 2: HUMAN REVIEW ─────────────────────────────────┐
│  Đọc plan, hiểu TỪNG resource                          │
│  Hỏi lại agent đoạn không hiểu — không approve mù      │
└────────────────────────────────────────────────────────┘
                          ↓
┌─ Lớp 3: POLICY-AS-CODE GATE ──────────────────────────┐
│  tflint  → checkov  → terraform plan                   │
│  → AI explain plan diff → human approve → apply        │
│  QUY TẮC: không pass checkov (no HIGH) thì không apply │
└────────────────────────────────────────────────────────┘
```

### 5.1. Vì sao cần cả 3 lớp

- Lớp 1 nhanh nhưng có thể sinh code "plausible-but-wrong".
- Lớp 2 bắt lỗi ý định, nhưng con người mệt mỏi, dễ bỏ sót.
- Lớp 3 tự động, nhất quán — bắt misconfiguration mà con người bỏ qua.

Ba lớp bù trừ cho nhau. Bỏ lớp nào cũng để lọt một loại lỗi.

### 5.2. Policy-as-Code — chi tiết

| Công cụ | Vai trò |
|---|---|
| **Checkov** | Industry-standard, open-source. 1000+ policy built-in, custom rule bằng Python/YAML. Resource connection graph. |
| **tfsec / Terrascan** | Scanner thay thế / bổ sung |
| **OPA + Rego** | Policy engine tùy biến. Rego khó học — có thể dùng AI sinh policy |
| **Sentinel** | Policy engine của HashiCorp (Terraform Cloud/Enterprise) |

Shift-left: bắt lỗ hổng lúc *generate*, không phải sau *deploy*.

---

## 6. Features — prompt patterns & công cụ

### 6.1. Ba prompt pattern cho IaC

| Pattern | Mô tả | Ví dụ |
|---|---|---|
| **Constraint-first** | Nêu ràng buộc TRƯỚC nội dung | "Phải dùng IRSA, KHÔNG tạo IAM user" |
| **Security-first** | Yêu cầu bảo mật mặc định | "RDS không public, encryption at rest bật, logging on" |
| **Cost-aware** | Nêu giới hạn chi phí | "Instance nhỏ nhất đủ chạy, single-AZ cho lab" |

### 6.2. Ví dụ prompt tốt

```
"Tạo reusable Terraform module cho AWS EKS cluster high-availability
với 3 managed node group (mỗi AZ một cái), IRSA cho cluster autoscaler,
tagging strategy nhất quán. Mọi resource phải có encryption-at-rest.
Không security group nào được mở 0.0.0.0/0. Trình bày plan trước khi tạo file."
```

### 6.3. AI-assisted review khác scanner tĩnh thế nào

| Scanner tĩnh (checkov) | AI-assisted review |
|---|---|
| Rule cố định, post-commit | Tương tác, contextual, real-time |
| Báo lỗi → bạn tự sửa | Đề xuất fix hội thoại, regenerate lặp |
| Bắt pattern đã biết | Xử lý custom policy, edge case ngoài rule tĩnh |

Hai cái **bổ sung** nhau — dùng cả hai.

### 6.4. AI giải thích `plan`

AI có thể đọc `terraform plan` và giải thích bằng tiếng người: mỗi resource tạo gì, rủi ro chỗ nào, cost ước tính bao nhiêu. Đây là cách *chống* lại "review 60 giây cho xong" — AI giúp review *sâu* nhanh hơn.

---

## 7. Implementation — Pipeline-as-Code với AI

### 7.1. Vòng lặp AI cho IaC

AI agent có thể chạy cả vòng: pull docs mới nhất → `terraform validate` (cú pháp) → `terraform plan` (preview) → `terraform apply` → kết nối AWS CLI / MCP server xác nhận resource. Sức mạnh thật là **tốc độ lặp** — viết, test, log, verify nhanh hơn người nhiều lần.

### 7.2. CI/CD pipeline do AI sinh

AI sinh được GitHub Actions / Jenkinsfile. Pattern stage chuẩn:

```
build  →  test  →  scan (trivy + checkov)  →  deploy (chỉ nhánh main)
```

Mẹo: dùng matrix build cho nhiều image, cache layer, secret qua GitHub Secrets / vault — KHÔNG hardcode.

### 7.3. Verification metric (nghiên cứu học thuật)

Nghiên cứu ICSE 2026 (TerraFormer) định nghĩa 5 mức verify cho IaC sinh tự động — đáng biết để có "ngôn ngữ chung":

1. **Compilability** — parse được, đúng cú pháp.
2. **Deployability** — khả thi triển khai (semantic, cloud constraint).
3. **Correctness** — đúng cú pháp + semantic + đúng *ý định* prompt.
4. **Linter pass** — qua tflint best-practice check.
5. **Security compliance** — % check checkov pass.

Bài học: "chạy được" (compilable) chỉ là mức thấp nhất. Mục tiêu là correctness + security compliance.

---

## 8. Best Practices

### 8.1. Ba quy tắc vàng (tổng hợp từ ngành)

1. **Không auto-apply khi chưa review plan.**
2. **Triển khai Policy-as-Code (OPA/Sentinel/checkov) TRƯỚC module AI-sinh đầu tiên** — lưới an toàn phải có sẵn, không phải dựng sau.
3. **Thiết kế Developer-Experience-Stack sao cho review là một phần của flow**, không phải nút thắt cổ chai.

### 8.2. Wrap LLM bằng organizational context

Case thật: một công ty dùng ChatGPT bulk-generate Terraform cho 80 microservice. "Chạy được" về kỹ thuật — nhưng không tuân tagging policy, module convention, team permission. Drift detection báo hàng trăm delta.

Giải pháp họ chuyển sang: **wrapper nội bộ quanh LLM**, prompt tự động inject context tổ chức — required tag, naming convention, known module repo. Bài học: AI cần được "nạp" context tổ chức, không để nó đoán.

### 8.3. Tagging — đừng quên

Tag/label resource là bắt buộc cho FinOps, compliance, automation cleanup. Resource không tag → biến mất khỏi cost report, để lỗ hổng governance. Có thể dùng AI audit: "quét folder, liệt kê resource thiếu tags block, sinh patch".

### 8.4. Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Apply không đọc plan | Lỗi cấu hình lọt prod — nguyên nhân #1 incident IaC đắt giá |
| Review "tick ô cho xong" | Misconfig plausible lọt qua |
| Không có policy gate trước module đầu tiên | Security debt tích lũy |
| Sửa tất cả lỗi checkov bằng 1 prompt | Agent dễ làm sai — sửa theo nhóm lỗi |
| Trộn Terraform + Crossplane cho cùng resource | Drift |

---

## 9. Case Study

### 9.1. Terraform cho InsightHub — bài Day 3

InsightHub cần infra: namespace EKS, RDS PostgreSQL (pgvector), ElastiCache Redis.

**Spec (constraint-first + security-first + cost-aware):**
- EKS: namespace `insighthub` trên cluster có sẵn — không tạo cluster mới.
- RDS PostgreSQL 16 có pgvector — không public, encryption at rest, single-AZ (lab).
- ElastiCache Redis — không public, trong VPC.
- IRSA cho pod IAM — không tạo IAM user.
- Instance nhỏ nhất đủ chạy (cost-aware).
- Secret qua AWS Secrets Manager — không hardcode.

**Quy trình 3-layer:** Claude Code + Terraform MCP sinh → học viên review plan → `tflint` + `checkov` → nếu HIGH thì prompt sửa theo nhóm lỗi → AI explain plan → apply.

### 9.2. Vì sao InsightHub là case tốt

- Có ràng buộc thật, đa dạng (network, DB, cache, IAM) — luyện đủ 3 prompt pattern.
- pgvector trên RDS là điểm dễ sai (extension cần parameter group) — luyện debug.
- Kết quả deploy lên cluster là nền cho Day 4 (observability) — running project thật sự *running*.

### 9.3. Bài học chống "speed outpacing safety"

Lời một junior dev trong khảo sát ngành: *"Tôi chỉ paste prompt, review YAML thấy ổn, rồi push."* — Đó chính xác là chỗ lỗi lọt vào. Day 3 dạy cách *ngược lại*: AI sinh nhanh, NHƯNG 3-layer defense đảm bảo không có gì lọt qua mà không được hiểu và kiểm.

---

## 10. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **IaC** — Infrastructure as Code.
- **HCL** — HashiCorp Configuration Language (cú pháp Terraform).
- **OpenTofu** — fork của Terraform, thuộc Linux Foundation.
- **Spec-driven** — viết spec có cấu trúc trước, AI sinh theo.
- **Policy-as-Code** — chính sách viết dạng code, enforce tự động (checkov, OPA/Rego).
- **3-Layer Defense** — AI generate → human review → policy gate.
- **Drift** — sai lệch giữa state thực tế và code.
- **IRSA** — IAM Roles for Service Accounts (EKS).
- **PR-driven workflow** — plan trên PR, apply qua approval (Atlantis/Spacelift).

### Đọc thêm (khuyến nghị trước buổi)

- Anthropic — "Effective context engineering for AI agents".
- HashiCorp — Terraform MCP server docs.

### Tự kiểm tra trước khi đến lớp

1. "Infrastructure as Intention" khác "as Code" thế nào?
2. Vì sao "code plausible" nguy hiểm hơn "code xấu"?
3. 3-Layer Defense gồm những lớp nào? Mỗi lớp bắt loại lỗi gì?
4. 3 prompt pattern cho IaC là gì?
5. Vì sao phải có policy gate TRƯỚC module AI-sinh đầu tiên?
6. AI-assisted review khác scanner tĩnh ở điểm nào?

---

*Pre-reading Day 3 — Module 7 AI-Native DevOps.*
