# Day 2 — Tài liệu đọc trước · Topic 1
# MCP — Kiến trúc & Khái niệm cốt lõi

> **Thời gian đọc:** ~25 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Vấn đề MCP giải quyết

Một AI agent tự nó chỉ biết những gì có trong training data + context. Nó **không**
tự kết nối được vào cluster Kubernetes, không query được database, không đọc được
file hệ thống của bạn.

Trước MCP: mỗi tích hợp là code tùy biến. Muốn agent nói chuyện với K8s → viết
integration riêng. Muốn nói chuyện với GitHub → viết integration khác. N agent ×
M tool = N×M tích hợp. Không scale.

**MCP (Model Context Protocol)** chuẩn hóa việc này: một giao thức chung để AI
agent kết nối tới tool và data source. Ví von kinh điển: **USB-C cho AI** — một
chuẩn cắm, mọi thiết bị dùng được.

### 1.2. Bối cảnh 2026

- MCP do Anthropic giới thiệu (cuối 2024), sau đó **donate cho Agentic AI
  Foundation** — vận hành dưới Linux Foundation. Tức MCP giờ là chuẩn mở, trung
  lập, không thuộc một công ty.
- Quy mô: ~97 triệu lượt download/tháng, hàng chục nghìn GitHub stars.
- Adoption: Anthropic, OpenAI, Google, AWS, Microsoft đều hỗ trợ MCP.
- Đây là **chuẩn de facto** để kết nối coding agent với tool — không còn là lựa
  chọn "thử nghiệm".

### 1.3. Vì sao DevOps engineer cần MCP

Với MCP, kỹ sư DevOps có thể hỏi agent bằng ngôn ngữ tự nhiên:

> *"Pod nào đang CrashLoopBackOff? Lấy log, tóm tắt nguyên nhân."*

thay vì gõ chuỗi `kubectl get` → `describe` → `logs` → đọc → suy luận. Công việc
vận hành chuyển từ **ghi nhớ cú pháp** sang **đối thoại có chủ đích**.

---

## 2. Concept & Core Components

### 2.1. Kiến trúc 3 thành phần

```
┌─────────────────────────────────┐
│  HOST  (Claude Code, Cursor...)  │
│  ┌─────────┐  ┌─────────┐        │
│  │ Client  │  │ Client  │  ...   │   mỗi client kết nối 1-1 với 1 server
│  └────┬────┘  └────┬────┘        │
└───────┼────────────┼─────────────┘
        │            │
   ┌────▼────┐  ┌────▼─────┐
   │ SERVER  │  │  SERVER  │   ...    expose tool/resource
   │  (k8s)  │  │ (docker) │
   └─────────┘  └──────────┘
```

| Thành phần | Vai trò | Ví dụ |
|---|---|---|
| **Host** | Ứng dụng AI chứa agent | Claude Code, Claude Desktop, Cursor |
| **Client** | Kết nối 1-1 với một server; nằm trong host | (host quản lý, ẩn với người dùng) |
| **Server** | Chương trình expose tool/resource cho agent | kubernetes-mcp-server, docker MCP |

### 2.2. Giao thức — JSON-RPC 2.0

MCP dùng **JSON-RPC 2.0** để host và server giao tiếp. Mỗi tương tác là một
request/response có cấu trúc — agent gọi tool, server trả kết quả. Bạn không cần
viết JSON-RPC tay; host và server lo việc đó. Nhưng cần biết: giao tiếp là **có
cấu trúc**, không phải "gửi text tự do".

### 2.3. Transports — hai cách kết nối

| Transport | Cơ chế | Dùng khi |
|---|---|---|
| **stdio** | Server chạy local, giao tiếp qua stdin/stdout | DevOps local — credentials không rời máy |
| **Streamable HTTP** | Server remote, giao tiếp qua HTTP | Server dùng chung cho team, cần scale |

**Khóa học dùng stdio.** Lý do bảo mật: với stdio, MCP server chạy trên máy bạn,
dùng credentials của bạn, và LLM chỉ nhận **kết quả tool call** — credentials
không bao giờ rời máy.

### 2.4. MCP Primitives — server expose những gì

| Primitive | Ý nghĩa | Ví dụ |
|---|---|---|
| **Tools** | Hành động agent gọi được | `list_pods`, `get_logs`, `scale_deployment` |
| **Resources** | Dữ liệu agent đọc được | nội dung file, config |
| **Prompts** | Prompt template dựng sẵn | `/k8s-diagnose` |
| **Sampling** | Server xin host gọi LLM giúp | server cần suy luận |
| **Elicitation** | Server xin host hỏi người dùng | server cần xác nhận |

Với DevOps, **Tools** là primitive dùng nhiều nhất.

---

## 3. Features — hệ sinh thái MCP server

### 3.1. Các MCP server quan trọng cho DevOps

| Server | Chức năng | Ghi chú |
|---|---|---|
| **Kubernetes** | Query/quản lý pod, deployment, service, log, Helm | `containers/kubernetes-mcp-server` — đầy đủ nhất, có `--read-only` |
| **Docker** | Inspect container, log, stats | Qua Docker MCP Toolkit hoặc npx |
| **Filesystem** | Đọc/ghi file (theo allow-list) | Official MCP server |
| **Prometheus** | Query PromQL bằng natural language | Dùng cho Day 4 |
| **Terraform** | Sinh code, query registry | HashiCorp official |
| **AWS** | Lambda, ECS, EKS, S3, RDS | AWS official |
| **GitHub** | PR, issue, git history | |

### 3.2. So sánh các Kubernetes MCP server

| Server | Ngôn ngữ | Đặc điểm |
|---|---|---|
| `containers/kubernetes-mcp-server` | Go | Đầy đủ nhất: `--read-only`, secrets masking, OpenTelemetry, prompt `/k8s-diagnose`. Hỗ trợ Claude Code, Desktop, Cursor, Codex, Gemini CLI |
| `Flux159/mcp-server-kubernetes` | TypeScript | Phổ biến, có pod cleanup utilities, non-destructive mode |
| `Blankcut/kubernetes-mcp-server` | — | Hướng GitOps, tích hợp ArgoCD/GitLab |

Khuyến nghị khóa học: `containers/kubernetes-mcp-server` (breadth tốt nhất).

### 3.3. Docker MCP Toolkit

Docker cung cấp MCP Toolkit — 300+ MCP server đã được container hóa, security-
hardened, deploy 1-click trong Docker Desktop. Ưu điểm: không phải quản lý
Node.js version, Python dependency, credentials plaintext cho từng server.

---

## 4. Implementation — cấu hình MCP cho Claude Code

### 4.1. Thêm MCP server

Claude Code dùng lệnh `claude mcp add` (đơn giản) hoặc `claude mcp add-json`
(cần cấu hình env phức tạp).

```bash
# Đơn giản
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$(pwd)"

# Có env (vd Kubernetes read-only với kubeconfig riêng)
claude mcp add-json kubernetes-mcp-server \
  '{"command":"npx","args":["-y","kubernetes-mcp-server@latest","--read-only"],
    "env":{"KUBECONFIG":"'${HOME}'/.kube/mcp-viewer.kubeconfig"}}' \
  -s user
```

### 4.2. Kiểm tra kết nối

```bash
claude mcp list
# kubernetes-mcp-server: ... - ✓ Connected
```

### 4.3. File `.mcp.json`

`.mcp.json` ở thư mục dự án lưu cấu hình MCP — cho phép **chia sẻ với team** qua
Git. Lưu ý: commit **cấu trúc**, KHÔNG commit credentials. Credentials để ở biến
môi trường.

### 4.4. Roadmap 2026

MCP đang chuẩn hóa nhanh: stateless HTTP, Tasks primitive (cho task dài), official
registry. Spec base hiện tại: 2025-11-25.

---

## 5. Best Practices

1. **Ưu tiên stdio** cho DevOps local — credentials không rời máy.
2. **Pin version** trong `.mcp.json` (`@latest` có thể break giữa khóa).
3. **Allow-list cho Filesystem** — chỉ cấp đúng thư mục cần, không cấp `/`.
4. **Dùng cờ `--read-only`** khi server hỗ trợ (Kubernetes).
5. **Một server — một mục đích** — đừng gộp quyền.
6. **`.mcp.json` commit cấu trúc, không commit secret.**
7. **Verify `claude mcp list`** trước khi bắt đầu làm việc.

---

## 6. Case Study — Debug pod crash: trước và sau MCP

**Bối cảnh:** một service của InsightHub trên K8s bị `CrashLoopBackOff`.

### Trước MCP — quy trình thủ công

```
kubectl get pods -n insighthub          # tìm pod lỗi
kubectl describe pod <pod> -n insighthub # đọc events
kubectl logs <pod> -n insighthub --previous  # đọc log crash
# → đọc, suy luận, đối chiếu config
```

Mất ~25 phút, phải nhớ cú pháp, dễ bỏ sót.

### Sau MCP — đối thoại

```
> Service nào của InsightHub đang không khỏe? Kiểm tra pod, lấy log,
  cho tôi biết nguyên nhân gốc.
```

Agent (qua Kubernetes MCP) tự: list pod → tìm pod lỗi → lấy log → describe →
tổng hợp RCA. Mất ~45 giây.

**Điểm cốt lõi của case study:** sự khác biệt KHÔNG phải vì AI "thông minh hơn
kỹ sư". Là vì AI **được kết nối** vào cluster qua MCP. MCP biến kiến thức của
agent thành **hành động** trên hệ thống thật. Đây cũng chính là lý do mục
Security (Day 6) quan trọng: khi agent hành động được, rủi ro cũng thật.

---

## Tự kiểm tra trước buổi học

1. MCP giải quyết vấn đề N×M integration như thế nào?
2. Ba thành phần Host / Client / Server làm gì?
3. Vì sao khóa học chọn stdio thay vì HTTP transport?
4. Primitive nào của MCP được DevOps dùng nhiều nhất?
5. `.mcp.json` nên commit gì và KHÔNG commit gì?

---

## Đọc thêm (tùy chọn)

- modelcontextprotocol.io — spec & docs chính thức
- github.com/containers/kubernetes-mcp-server — Kubernetes MCP
