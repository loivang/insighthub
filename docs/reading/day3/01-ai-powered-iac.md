# Day 3 — Tài liệu đọc trước · Topic 1
# AI-Powered Infrastructure as Code

> **Thời gian đọc:** ~25 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Ôn lại: Infrastructure as Code

IaC = mô tả hạ tầng (VPC, cluster, database...) bằng **code khai báo**, thay vì
click chuột trên console. Lợi ích: version control, reproducible, review được,
tự động hóa được. Terraform là công cụ IaC phổ biến nhất.

Học viên đã quen Terraform ở các module trước. Day 3 không dạy lại Terraform —
mà dạy **cách dùng AI để viết IaC nhanh hơn mà vẫn an toàn**.

### 1.2. Vì sao IaC + AI là cặp đôi tự nhiên

IaC là code khai báo, có cấu trúc rõ, có schema (provider, resource, argument).
Đây là loại bài toán AI agent làm rất tốt — khác với code nghiệp vụ mơ hồ.

Nhưng có một cái bẫy: AI sinh IaC **rất nhanh**, và IaC sai trong production
**rất đắt** (mất dữ liệu, lộ dữ liệu, downtime). Tốc độ mà không có kiểm soát =
nguy hiểm. Day 3 dạy cách cân bằng.

### 1.3. Spec-driven development

Thay vì gõ Terraform từng dòng, kỹ sư mô tả **spec**: yêu cầu + ràng buộc. AI
sinh code từ spec, người review. Spec rõ ràng = output tốt. Spec mơ hồ = AI đoán
sai.

---

## 2. Concept & Core Components

### 2.1. Mô hình 3-Layer Defense

Đây là concept trung tâm của Day 3:

```
Lớp 1: AI GENERATE      Claude Code + Terraform MCP sinh module
        ↓
Lớp 2: HUMAN REVIEW     Kỹ sư đọc, hiểu từng resource, đặt câu hỏi
        ↓
Lớp 3: POLICY-AS-CODE   tflint + checkov + terraform plan (gate tự động)
        ↓
        AI explain plan → Human approve → terraform apply
```

Không lớp nào thay thế lớp nào. AI nhanh (lớp 1), người hiểu ngữ cảnh (lớp 2),
máy kiểm tra nhất quán (lớp 3).

### 2.2. Core components

| Component | Vai trò |
|---|---|
| **Claude Code** | Agent sinh & sửa Terraform |
| **Terraform MCP server** | Cho agent query registry, tránh hallucinate resource/argument |
| **tflint** | Lint: cú pháp, naming, deprecated argument |
| **checkov** | Quét security misconfiguration — policy-as-code |
| **terraform plan** | Xem trước thay đổi sẽ áp dụng |

### 2.3. Policy-as-Code là gì

Thay vì review bảo mật bằng mắt người (không nhất quán, dễ sót), **policy-as-code**
mã hóa quy tắc bảo mật thành code, máy kiểm tra tự động. `checkov` có sẵn hàng
trăm policy: "RDS phải encryption at rest", "S3 không được public", "EKS phải bật
logging"...

---

## 3. Features — Prompt patterns cho IaC

### 3.1. Constraint-first

Nêu ràng buộc **trước** nội dung. AI đọc tuần tự — ràng buộc đầu prompt định hình
toàn bộ output.

### 3.2. Ba pattern ràng buộc quan trọng

| Pattern | Mô tả | Ví dụ ràng buộc |
|---|---|---|
| **Security-first** | Bảo mật là mặc định, không phải thêm sau | "RDS không public, encryption at rest bật, trong private subnet" |
| **Least-privilege** | IAM tối thiểu | "Dùng IRSA cho pod, KHÔNG tạo IAM user, KHÔNG dùng `*` trong policy" |
| **Cost-aware** | Có ý thức chi phí | "Instance nhỏ nhất đủ chạy, single-AZ cho môi trường lab" |

### 3.3. Yêu cầu plan trước khi sửa

Luôn yêu cầu agent trình bày plan trước khi tạo/sửa file `.tf`. IaC sai tốn kém —
review plan là rẻ.

### 3.4. AI explain plan

Sau `terraform plan`, yêu cầu agent **giải thích plan bằng tiếng người**: mỗi
resource sẽ tạo gì, rủi ro gì, cost ước tính bao nhiêu. Đây là cách biến output
kỹ thuật khô khan thành thông tin review được.

---

## 4. Implementation — quy trình sinh IaC bằng AI

### 4.1. Vòng làm việc đầy đủ

```
1. Viết spec (mục tiêu + ràng buộc constraint-first)
2. Agent sinh Terraform module  → đọc PLAN agent đưa ra
3. tflint                       → sửa lint issue
4. checkov -d .                 → sửa security issue (ưu tiên HIGH)
5. terraform plan               → AI explain plan
6. Human review & approve
7. terraform apply
```

### 4.2. Spec mẫu cho InsightHub

InsightHub cần: namespace trên EKS, RDS PostgreSQL có pgvector, ElastiCache Redis.

```
[MỤC TIÊU] Terraform module cho hạ tầng InsightHub trên AWS.
[RÀNG BUỘC — security-first]
  - RDS PostgreSQL 16, có pgvector — KHÔNG public, encryption at rest,
    trong private subnet
  - ElastiCache Redis — KHÔNG public, trong VPC
[RÀNG BUỘC — least-privilege]
  - Dùng IRSA cho pod IAM, KHÔNG tạo IAM user
  - Secret qua AWS Secrets Manager, KHÔNG hardcode
[RÀNG BUỘC — cost-aware]
  - Instance nhỏ nhất đủ chạy, single-AZ (môi trường lab)
[QUY TRÌNH] Tổ chức thành module có cấu trúc. Trình bày plan trước khi tạo file.
```

### 4.3. Xử lý lỗi checkov

Khi checkov báo HIGH, đưa output cho agent sửa **theo nhóm**, không sửa tất cả
một lần:

```
> checkov báo các lỗi HIGH sau: [paste]. Sửa Terraform để pass,
  giải thích từng thay đổi và vì sao nó an toàn hơn.
```

---

## 5. Best Practices

1. **Constraint-first** — ràng buộc đặt đầu spec.
2. **Security-first** — bảo mật là mặc định, không phải tính năng thêm sau.
3. **Luôn qua policy gate** — không apply khi checkov còn HIGH severity.
4. **Pin provider version** — tránh AI sinh code với version trôi nổi.
5. **AI explain plan** — biến `terraform plan` thành thông tin review được.
6. **Review từng resource** — "resource nào bạn không hiểu, hỏi lại agent".
7. **Sửa lỗi checkov theo nhóm**, không một phát.
8. **State file an toàn** — `.tfstate` không commit Git (đã có trong `.gitignore`).

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Vibe-coding IaC: AI sinh → apply thẳng | Misconfiguration vào production |
| Bỏ qua checkov "cho nhanh" | Lộ dữ liệu, resource public ngoài ý muốn |
| Không pin provider version | Build không reproducible |
| Apply mà không đọc plan | Xóa/đổi resource ngoài ý muốn |

---

## 6. Case Study — Một dòng Terraform thiếu, một sự cố lộ dữ liệu

**Bối cảnh điển hình trong ngành:** AI agent được yêu cầu sinh Terraform cho một
RDS database. Prompt chỉ nói *"tạo RDS PostgreSQL cho app"* — không có ràng buộc
security-first.

Agent sinh code hợp lệ, `terraform apply` chạy thành công, app kết nối được. Mọi
thứ "trông ổn". Nhưng module thiếu:

- `publicly_accessible = false`
- `storage_encrypted = true`

RDS được tạo **public**, **không mã hóa**. Vài tuần sau, một scan bảo mật phát
hiện database lộ ra Internet.

### Nếu áp dụng 3-Layer Defense

- **Lớp 1 (AI generate):** vẫn sinh code thiếu — vì prompt không nêu ràng buộc.
- **Lớp 2 (Human review):** kỹ sư đọc plan, *có thể* nhận ra — nhưng con người
  không nhất quán, dễ sót.
- **Lớp 3 (checkov):** chắc chắn bắt được. `checkov` có policy
  `CKV_AWS_17` (RDS không public) và `CKV_AWS_16` (RDS encryption) — báo HIGH,
  chặn apply.

**Bài học:** AI sinh code "trông đúng" không có nghĩa là "an toàn". Con người
review là cần nhưng không đủ — con người sót. **Policy-as-code (lớp 3) là lưới
an toàn nhất quán**. Đó là lý do quy tắc "không apply khi còn HIGH severity" là
bắt buộc, không phải tùy chọn.

---

## Tự kiểm tra trước buổi học

1. Vì sao IaC là loại bài toán AI agent làm tốt?
2. 3-Layer Defense gồm những lớp nào? Lớp nào kiểm tra nhất quán nhất?
3. Phân biệt 3 pattern ràng buộc: security-first, least-privilege, cost-aware.
4. Policy-as-code là gì? checkov làm gì?
5. Vì sao "con người review" là cần nhưng chưa đủ?

---

## Đọc thêm (tùy chọn)

- Tài liệu checkov — danh sách policy
- HashiCorp — Terraform MCP server
