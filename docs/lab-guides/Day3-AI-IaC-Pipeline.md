# Lab Guide — Day 3: AI-Powered IaC & Pipeline Engineering

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 3, học viên có thể:

1. Dùng AI sinh Terraform module production-grade cho InsightHub (EKS namespace, RDS pgvector, ElastiCache Redis).
2. Áp dụng 3-layer defense: AI generate → human review → policy-as-code gate.
3. Sinh CI/CD pipeline bằng AI và deploy InsightHub lên K8s cluster.
4. Nhận diện và tránh anti-pattern "vibe-coding IaC vào production".

**Daily Artifact:** Terraform module pass `checkov` (no HIGH) + CI/CD pipeline green + InsightHub live trên cluster.

---

## Chuẩn bị trước buổi

- [ ] Terraform v1.9+, tflint, checkov, GitHub CLI đã cài
- [ ] `.mcp.json` có Terraform MCP server
- [ ] Lab cluster K8s sẵn sàng (`kubectl get nodes` OK)
- [ ] Đã đọc "Effective context engineering for AI agents"

---

## Segment 1 — Recap (10 phút)

- Day 2 đã kết nối MCP. Hôm nay dùng MCP để **làm việc thật** — không chỉ query.
- "AI sinh IaC trong 2 phút. Nhưng IaC sai trong production tốn cả ngày. Hôm nay học cách AI sinh nhanh MÀ vẫn an toàn."

---

## Segment 2 — Concept: Spec-driven IaC với AI (30 phút)

### 2.1. Spec-driven development

Thay vì gõ Terraform từng dòng: mô tả **spec** (yêu cầu + ràng buộc), AI sinh, người review. Spec rõ = output tốt.

### 2.2. Prompt patterns cho IaC

| Pattern | Mô tả | Ví dụ |
|---|---|---|
| **Constraint-first** | Nêu ràng buộc trước nội dung | "Phải dùng IRSA, không tạo IAM user" |
| **Security-first** | Yêu cầu bảo mật mặc định | "RDS không public, encryption at rest bật" |
| **Cost-aware** | Nêu giới hạn cost | "Dùng instance nhỏ nhất đủ chạy, single-AZ cho lab" |

### 2.3. Terraform MCP server

Terraform MCP (HashiCorp official) cho agent query registry, tìm module, kiểm tra provider — giảm hallucination về resource/argument.

---

## Segment 3 — Best Practice: 3-Layer Defense (30 phút)

### 3.1. Anti-pattern: vibe-coding IaC vào prod

AI sinh Terraform → apply thẳng → 💥. Không review, không scan = thảm họa chờ sẵn.

### 3.2. Pattern đúng — 3 lớp

```
Lớp 1: AI generate     → Claude Code + Terraform MCP sinh module
Lớp 2: Human review    → đọc plan, hiểu từng resource
Lớp 3: Policy-as-code  → tflint + checkov + terraform plan, gate tự động
                          → AI explain plan diff → human approve → apply
```

### 3.3. Công cụ lớp 3

| Tool | Vai trò |
|---|---|
| `tflint` | Lint cú pháp, naming, deprecated |
| `checkov` | Quét security misconfiguration (policy-as-code) |
| `terraform plan` | Xem thay đổi trước khi apply |

**Quy tắc:** không có HIGH severity của checkov thì mới được apply.

---

## Segment 4 — Live Demo + Lab (60 phút)

### Phần A — Sinh Terraform cho InsightHub (35 phút)

InsightHub cần infra: EKS namespace, RDS PostgreSQL (pgvector), ElastiCache Redis.

**Bước 1 — Spec cho Claude Code:**

```
Tạo Terraform module trong thư mục infra/ cho InsightHub trên AWS.
Ràng buộc (constraint-first):
- EKS: tạo namespace 'insighthub' trên cluster có sẵn (không tạo cluster mới)
- RDS PostgreSQL 16, có pgvector — KHÔNG public, encryption at rest, single-AZ (lab)
- ElastiCache Redis — KHÔNG public, trong VPC
- Dùng IRSA cho pod IAM, KHÔNG tạo IAM user
- Instance nhỏ nhất đủ chạy (cost-aware, môi trường lab)
- Mọi secret qua AWS Secrets Manager, không hardcode
Tổ chức thành module có cấu trúc rõ. Viết README + biến đầu vào.
Trình bày plan trước khi tạo file.
```

**Bước 2 — Review:** học viên đọc plan agent đưa ra. Trainer hỏi: "Resource nào bạn không hiểu? Hỏi lại agent."

**Bước 3 — Policy gate:**

```bash
cd infra
tflint
checkov -d .
terraform init
terraform plan
```

Nếu checkov báo HIGH → prompt cho agent sửa:

```
checkov báo các lỗi HIGH severity sau: [paste output].
Sửa Terraform để pass, giải thích từng thay đổi.
```

**Bước 4 — AI explain plan:**

```
Giải thích terraform plan này bằng tiếng Việt: mỗi resource sẽ tạo gì,
có gì rủi ro, cost ước tính bao nhiêu.
```

**Bước 5 — Apply** (sau khi review): `terraform apply`.

### Phần B — Workshop: CI/CD pipeline (25 phút)

InsightHub có 3 image (web, api, ingestion-worker). Cần pipeline build cả 3.

**Prompt:**

```
Tạo GitHub Actions workflow trong .github/workflows/ cho InsightHub.
Stages:
- build: build 3 image (web, api, ingestion-worker)
- test: chạy test cơ bản
- scan: quét vulnerability image (trivy) + checkov cho infra/
- deploy: deploy lên namespace insighthub trên EKS (chỉ khi nhánh main)
Dùng matrix cho build 3 image. Cache layer. Secret qua GitHub Secrets.
```

Học viên commit, push, xem pipeline chạy. Mục tiêu: pipeline **green**.

---

## Segment 5 — Workshop & Support (20 phút)

- Học viên verify InsightHub live trên cluster: `kubectl -n insighthub get pods`.
- Truy cập InsightHub qua service/ingress, smoke test.
- Q&A.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | Terraform module | `checkov -d infra/` → no HIGH severity |
| 2 | CI/CD pipeline | Workflow run green trên GitHub |
| 3 | InsightHub live trên K8s | `kubectl -n insighthub get pods` tất cả Running; truy cập được UI |
| 4 | AI prompt log | Lưu prompt đã dùng |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| `terraform plan` lỗi provider | Provider version chưa pin | Pin version trong `required_providers` |
| checkov nhiều HIGH | AI sinh thiếu security default | Prompt sửa từng nhóm lỗi, không sửa tất cả 1 lần |
| Pipeline fail ở build | Dockerfile path sai trong workflow | Kiểm tra context path từng image |
| Pod `ImagePullBackOff` | Image chưa push / sai registry | Kiểm tra registry credentials trong pipeline |
| RDS connect timeout | Security group chặn | Kiểm tra SG cho phép EKS → RDS port 5432 |
| pgvector không có trên RDS | Extension chưa enable | RDS cần parameter group cho phép, hoặc `CREATE EXTENSION` sau |

---

## Homework (chuẩn bị Day 4)

1. Hoàn tất deploy nếu chưa xong.
2. Tạo Grafana Cloud free account.
3. Verify `kube-prometheus-stack` chạy trên cluster (hoặc cài).
4. Đọc bài về AI anomaly detection 2026.

---

## Ghi chú cho Trainer

- Cost cảnh báo: RDS + ElastiCache thật tốn tiền. Nếu budget hạn chế, cho học viên dùng RDS/ElastiCache nhỏ nhất + tear down ngay sau Day 7. Hoặc dùng Postgres/Redis pod trong cluster (StatefulSet) thay cho managed service — vẫn dạy được, rẻ hơn.
- checkov HIGH thường gặp với RDS/EKS: encryption, public access, logging. Để sẵn checklist các lỗi điển hình.
- Nếu lớp không kịp Phần B: pipeline có thể thành homework, nhưng InsightHub phải live trên cluster bằng `kubectl apply` thủ công trước.
- Đáp án Terraform + pipeline: build dần, thêm vào `docs/reference-solutions/` khớp công cụ hiện hành.
