# Lab Guide — Day 2: MCP Protocol — USB-C cho AI Agents

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 2, học viên có thể:

1. Giải thích kiến trúc MCP: Host / Client / Server, JSON-RPC, transports.
2. Cấu hình ≥ 4 MCP server cho Claude Code (filesystem, docker, kubernetes, prometheus).
3. Debug InsightHub bằng natural language qua MCP thay vì gõ kubectl/docker thủ công.
4. Áp dụng nguyên tắc least-privilege khi cấp quyền cho AI agent.

**Daily Artifact:** `docker-compose` đủ 5 service chạy được + `.mcp.json` cấu hình 4+ server + log 1 phiên debug InsightHub qua MCP.

---

## Chuẩn bị trước buổi

- [ ] Refactor Day 1 hoàn tất (5 service)
- [ ] Đọc spec MCP overview tại modelcontextprotocol.io
- [ ] AWS IAM user `mcp-readonly` đã tạo (policy `ReadOnlyAccess`)
- [ ] kubeconfig context cho lab cluster đã setup
- [ ] Docker Desktop đang chạy

---

## Segment 1 — Recap & Hook (10 phút)

**Demo before/after của trainer:**

- *Before:* debug 1 pod InsightHub crash — `kubectl get pods` → `kubectl describe` → `kubectl logs` → đọc → suy luận. Mất ~25 phút.
- *After:* hỏi Claude Code: *"Pod nào của InsightHub đang lỗi? Lấy log và tóm tắt nguyên nhân."* → ~45 giây.

**Hook:** "Sự khác biệt không phải Claude thông minh hơn bạn. Là Claude **kết nối được** vào cluster. MCP là cái cổng kết nối đó."

---

## Segment 2 — Concept: Kiến trúc MCP (40 phút)

### 2.1. MCP là gì

Model Context Protocol — chuẩn mở để AI agent kết nối tới tool và data source bên ngoài. Ví von: **USB-C cho AI** — một chuẩn cắm, mọi thiết bị.

Bối cảnh 2026: MCP đã được donate cho **Agentic AI Foundation** (dưới Linux Foundation). ~97M downloads/tháng. Anthropic, OpenAI, Google, AWS, Microsoft đều support.

### 2.2. Ba thành phần

| Thành phần | Vai trò | Ví dụ |
|---|---|---|
| **Host** | Ứng dụng AI chứa agent | Claude Code, Claude Desktop, Cursor |
| **Client** | Kết nối 1-1 với 1 server, nằm trong host | (ẩn — host quản lý) |
| **Server** | Expose tool/resource cho agent | kubernetes-mcp-server, docker MCP |

### 2.3. Transports

| Transport | Đặc điểm | Dùng khi |
|---|---|---|
| **stdio** | Server chạy local, giao tiếp qua stdin/stdout | DevOps local — credentials không rời máy |
| **Streamable HTTP** | Server remote, qua HTTP | Server dùng chung cho team, scale |

**Cho khóa học: stdio** — vì credentials (kubeconfig, AWS key) ở lại máy học viên, không gửi đi đâu.

### 2.4. MCP primitives

- **Tools** — hành động agent gọi được (list pods, get logs...).
- **Resources** — dữ liệu agent đọc được (file, config...).
- **Prompts** — prompt template dựng sẵn.
- **Sampling / Elicitation** — server xin host gọi LLM / hỏi người dùng.

### 2.5. Roadmap 2026

Stateless HTTP, Tasks primitive, official registry — MCP đang chuẩn hóa nhanh.

---

## Segment 3 — Best Practice: Bảo mật MCP (30 phút)

### 3.1. Credentials stay local

Với stdio transport, MCP server chạy trên máy bạn, dùng credentials của bạn. Claude (LLM) chỉ nhận **kết quả tool call**, không nhận credentials.

### 3.2. Least-privilege — nguyên tắc quan trọng nhất

> **MCP server kế thừa quyền của bạn. Nếu kubeconfig của bạn là cluster-admin, thì Claude cũng là cluster-admin.**

Phòng vệ:
- Kubernetes: tạo ServiceAccount riêng + ClusterRole **read-only**, kubeconfig riêng cho MCP.
- AWS: IAM user `mcp-readonly` với `ReadOnlyAccess`.
- Dùng cờ `--read-only` của kubernetes-mcp-server.
- Blast radius bị giới hạn bởi RBAC, không phải bởi "thiện chí" của MCP server.

### 3.3. Context pinning

Rủi ro thật: bạn bảo "xóa pod kẹt ở staging", agent chạy nhầm context `production`. Luôn pin context cụ thể trong cấu hình MCP server.

### 3.4. Allow-list cho filesystem

Filesystem MCP chỉ cấp đúng thư mục cần thiết, không cấp toàn bộ `/`.

---

## Segment 4 — Live Demo + Lab: Cấu hình MCP cho InsightHub (50 phút)

### Bước 1 — Tạo kubeconfig read-only cho MCP

Trên lab cluster (trainer hướng dẫn ServiceAccount cụ thể theo cluster). Mục tiêu: có file `~/.kube/mcp-viewer.kubeconfig` chỉ quyền đọc.

Verify: `kubectl --kubeconfig ~/.kube/mcp-viewer.kubeconfig get pods` chạy được, nhưng `delete` thì bị từ chối.

### Bước 2 — Thêm MCP server vào Claude Code

Claude Code dùng lệnh `claude mcp add` hoặc `claude mcp add-json`.

**Filesystem MCP** (chỉ cấp thư mục repo InsightHub):

```bash
cd insighthub
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$(pwd)"
```

**Docker MCP** (qua Docker MCP Toolkit hoặc npx — theo doc hiện hành):

```bash
claude mcp add docker -- npx -y docker-mcp-server@latest
```

**Kubernetes MCP** (read-only, dùng kubeconfig riêng):

```bash
claude mcp add-json kubernetes-mcp-server \
  '{"command":"npx","args":["-y","kubernetes-mcp-server@latest","--read-only"],"env":{"KUBECONFIG":"'${HOME}'/.kube/mcp-viewer.kubeconfig"}}' \
  -s user
```

**Prometheus MCP** (chuẩn bị cho Day 4):

```bash
claude mcp add prometheus -- npx -y prometheus-mcp-server@latest
```

### Bước 3 — Verify kết nối

```bash
claude mcp list
```

Mỗi server phải hiện `✓ Connected`. Nếu không, xem Troubleshooting.

### Bước 4 — Lưu cấu hình vào `.mcp.json`

`.mcp.json` ở thư mục dự án cho phép chia sẻ cấu hình MCP với team (commit vào Git được — nhưng KHÔNG commit credentials, chỉ commit cấu trúc).

```bash
cp .mcp.json.template .mcp.json
```

Điền cấu hình 4 server. Credentials để ở biến môi trường, không hardcode.

### Bước 5 — Debug InsightHub qua MCP

Trainer cố ý làm 1 service InsightHub lỗi (vd: đổi `DATABASE_URL` sai trong worker). Học viên dùng Claude Code:

```
Service nào của InsightHub đang không khỏe? Kiểm tra container/pod,
lấy log, và cho tôi biết nguyên nhân gốc.
```

Quan sát Claude gọi Docker MCP / Kubernetes MCP, đọc log, suy luận RCA.

### Bước 6 — Workshop: AWS MCP read-only

Học viên tự thêm AWS MCP với IAM `mcp-readonly`:

```bash
claude mcp add-json aws \
  '{"command":"npx","args":["-y","aws-mcp-server@latest"],"env":{"AWS_PROFILE":"mcp-readonly"}}'
```

**Verify least-privilege:** yêu cầu Claude thử 1 hành động ghi (vd tạo S3 bucket) → phải bị IAM từ chối. Đây là bằng chứng least-privilege hoạt động.

---

## Segment 5 — Workshop & Mini-quiz (20 phút)

**Mini-quiz 10 câu** (trainer chuẩn bị) — ví dụ:
1. stdio vs HTTP transport khác nhau ở đâu?
2. Vì sao credentials không rời máy với stdio?
3. MCP server kế thừa quyền từ đâu?
4. Context pinning giải quyết rủi ro gì?

Học viên hoàn thiện `.mcp.json`, commit.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | `docker-compose` 5 service | `docker compose up` OK |
| 2 | `.mcp.json` cấu hình 4+ server | `claude mcp list` → tất cả `✓ Connected` |
| 3 | Log phiên debug qua MCP | Học viên lưu transcript phiên Claude Code debug InsightHub |
| 4 | Verify least-privilege | Screenshot hành động ghi bị IAM từ chối |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| MCP server không `Connected` | npx chưa tải được package | Kiểm tra mạng, thử `npx -y <pkg> --help` |
| Kubernetes MCP không thấy cluster | KUBECONFIG sai đường dẫn | Dùng đường dẫn tuyệt đối, không `~` |
| `kubectl get pods` OK nhưng MCP fail | MCP dùng kubeconfig khác | Kiểm tra biến `KUBECONFIG` trong cấu hình MCP |
| AWS MCP cho phép cả hành động ghi | Dùng nhầm profile admin | Đảm bảo `AWS_PROFILE=mcp-readonly` |
| Claude không gọi MCP tool | Tool search chưa load | Hỏi cụ thể hơn, hoặc kiểm tra server đã `Connected` |

---

## Homework (chuẩn bị Day 3)

1. Hoàn thiện `.mcp.json` nếu chưa xong.
2. Cài Terraform v1.9+, tflint, checkov, GitHub CLI.
3. Đọc bài "Effective context engineering for AI agents" của Anthropic.
4. Đảm bảo lab cluster còn chạy được.

---

## Ghi chú cho Trainer

- Tên package MCP server thay đổi nhanh — kiểm tra lại tên/lệnh chính xác 1 ngày trước buổi học tại modelcontextprotocol.io và repo containers/kubernetes-mcp-server.
- containers/kubernetes-mcp-server là lựa chọn breadth tốt nhất (Go, npm/PyPI, có `--read-only`, secrets masking, `/k8s-diagnose`).
- Pin version trong `.mcp.json` để tránh break giữa khóa (Risk R6).
- Chuẩn bị sẵn 1 service InsightHub "lỗi có chủ đích" cho Bước 5.
- Nếu lab cluster chưa sẵn sàng: dùng kind/k3d local, kubernetes-mcp-server vẫn hoạt động.
