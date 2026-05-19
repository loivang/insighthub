# Day 3 — Tài liệu đọc trước · Topic 2
# AI-Generated CI/CD Pipelines

> **Thời gian đọc:** ~18 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Ôn lại CI/CD

- **CI (Continuous Integration):** mỗi thay đổi code được build + test tự động.
- **CD (Continuous Delivery/Deployment):** thay đổi đã qua test được đưa lên môi
  trường tự động.

Pipeline là chuỗi các stage tự động hóa vòng này. Học viên đã quen CI/CD ở module
trước (Jenkins / GitHub Actions). Day 3 dạy cách dùng AI để **sinh và bảo trì**
pipeline.

### 1.2. Pipeline-as-Code

Pipeline hiện đại được mô tả bằng code (YAML cho GitHub Actions, Groovy cho
Jenkins), nằm trong repo. Vì là code có cấu trúc → AI agent sinh tốt.

### 1.3. Vì sao AI sinh pipeline hữu ích

Viết pipeline đúng chuẩn tốn công: matrix build, cache, secret management, các
stage scan bảo mật. AI agent biết các pattern này — sinh nhanh một pipeline đầy
đủ, kỹ sư review và tinh chỉnh.

---

## 2. Concept & Core Components

### 2.1. Các stage của một pipeline tốt

```
build → test → scan → deploy
```

| Stage | Làm gì | Công cụ ví dụ |
|---|---|---|
| **build** | Build artifact / Docker image | docker build |
| **test** | Chạy unit/integration test | pytest, jest |
| **scan** | Quét lỗ hổng image + IaC | trivy (image), checkov (IaC) |
| **deploy** | Đưa lên môi trường | kubectl, helm |

### 2.2. Core components của GitHub Actions

| Khái niệm | Ý nghĩa |
|---|---|
| **Workflow** | File YAML trong `.github/workflows/` |
| **Job** | Một nhóm step chạy trên cùng runner |
| **Step** | Một hành động đơn (chạy lệnh hoặc dùng action) |
| **Matrix** | Chạy job nhiều lần với tham số khác nhau |
| **Secret** | Giá trị nhạy cảm, không lộ trong log |

### 2.3. Vì sao InsightHub cần matrix build

InsightHub có **3 image**: `web`, `api`, `ingestion-worker`. Thay vì viết 3 job
giống nhau, dùng **matrix** — một job định nghĩa, chạy 3 lần với 3 tham số. Code
ngắn hơn, dễ bảo trì hơn.

---

## 3. Features — pipeline chất lượng cao gồm gì

### 3.1. Matrix build

```yaml
strategy:
  matrix:
    service: [web, api, ingestion-worker]
```

Một job, chạy song song cho cả 3 service.

### 3.2. Layer caching

Build Docker image lại từ đầu mỗi lần rất chậm. Cache layer → build nhanh hơn
nhiều. AI agent biết pattern này — nhắc trong spec để agent thêm.

### 3.3. Security scan trong pipeline

- **trivy** — quét lỗ hổng trong Docker image (CVE trong base image, dependency).
- **checkov** — quét misconfiguration trong thư mục `infra/`.

Scan nằm **trong pipeline** = mỗi lần push đều được kiểm tra, không phụ thuộc ý
thức cá nhân.

### 3.4. Secret management

Credential (registry, kubeconfig, API key) lưu trong **GitHub Secrets** — pipeline
đọc qua biến môi trường, không hardcode trong YAML, không lộ trong log.

### 3.5. Deployment gate

Deploy chỉ chạy khi: nhánh là `main`, các stage trước (build/test/scan) đã pass.
Có thể thêm approval gate thủ công cho môi trường production.

---

## 4. Implementation — sinh pipeline cho InsightHub

### 4.1. Spec mẫu

```
[MỤC TIÊU] GitHub Actions workflow cho InsightHub.
[STAGES]
  - build: build 3 image (web, api, ingestion-worker) — dùng matrix
  - test:  chạy test cơ bản
  - scan:  trivy cho image + checkov cho infra/
  - deploy: deploy lên namespace insighthub trên EKS, CHỈ khi nhánh main
[RÀNG BUỘC]
  - Cache layer để build nhanh
  - Secret qua GitHub Secrets, không hardcode
  - deploy chỉ chạy khi build + test + scan đều pass
[QUY TRÌNH] Trình bày plan trước.
```

### 4.2. Review pipeline AI sinh

Kiểm tra các điểm AI hay làm thiếu/sai:

- [ ] Context path từng image build đúng chưa? (`./web`, `./api`...)
- [ ] Có dùng matrix không, hay viết lặp 3 job?
- [ ] Secret có hardcode nhầm trong YAML không?
- [ ] Stage scan có thật sự chặn pipeline khi tìm thấy lỗ hổng không?
- [ ] Deploy có điều kiện nhánh `main` chưa?

### 4.3. Verify

Push code → xem pipeline chạy trên tab Actions của GitHub. Mục tiêu: **green**
(tất cả stage pass).

---

## 5. Best Practices

1. **Pipeline đầy đủ 4 stage** — đừng bỏ scan "cho nhanh".
2. **Matrix cho việc lặp** — 3 image dùng 1 job matrix.
3. **Cache layer** — build nhanh, tiết kiệm thời gian pipeline.
4. **Secret qua GitHub Secrets** — không bao giờ hardcode.
5. **Scan phải chặn được pipeline** — scan mà không fail pipeline khi có lỗ hổng
   thì vô nghĩa.
6. **Deploy có điều kiện** — chỉ nhánh `main`, chỉ khi stage trước pass.
7. **Review context path** — lỗi AI sinh pipeline hay gặp nhất.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Bỏ stage scan | Image có CVE lọt production |
| Hardcode secret trong YAML | Credential lộ trong Git/log |
| Scan chạy nhưng không fail pipeline | Scan trang trí, không bảo vệ |
| Lặp 3 job thay vì matrix | Pipeline khó bảo trì |
| Deploy mọi nhánh | Nhánh feature đẩy nhầm lên production |

---

## 6. Case Study — Pipeline "green" nhưng không an toàn

**Bối cảnh:** một team yêu cầu AI sinh pipeline cho app 3 service. Prompt chỉ nói
*"build, test, deploy"* — quên nhắc stage scan.

AI sinh pipeline gọn gàng, chạy **green** ngay lần đầu. Team hài lòng, merge.

Ba tuần sau: một CVE nghiêm trọng được công bố trong base image `node` mà cả 3
service dùng. Vì pipeline **không có stage scan**, không ai biết — image lỗ hổng
vẫn chạy production cho tới khi một audit thủ công phát hiện.

### Nếu spec có ràng buộc đầy đủ

Nếu prompt nêu rõ *"scan: trivy cho image"*, AI sẽ thêm stage scan. Mỗi lần
pipeline chạy, trivy quét image — CVE mới công bố sẽ làm pipeline **fail**, buộc
team cập nhật base image trước khi deploy.

**Bài học:** "pipeline green" chỉ có nghĩa "các stage *được định nghĩa* đã pass".
Nó KHÔNG có nghĩa "an toàn". AI sinh chính xác những gì bạn yêu cầu — nếu bạn
quên yêu cầu scan, AI không tự thêm. **Chất lượng pipeline = chất lượng spec.**
Đây cũng là lý do mục review (mục 4.2) cần checklist rõ ràng.

---

## Tự kiểm tra trước buổi học

1. Bốn stage của một pipeline tốt là gì?
2. Vì sao InsightHub nên dùng matrix build?
3. trivy và checkov quét cái gì khác nhau?
4. "Scan phải chặn được pipeline" nghĩa là gì?
5. Vì sao "pipeline green" không đồng nghĩa với "an toàn"?

---

## Đọc thêm (tùy chọn)

- GitHub Actions docs — workflow syntax
- Tài liệu trivy — container image scanning
