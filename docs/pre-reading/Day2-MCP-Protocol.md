# Pre-Reading — Day 2: Model Context Protocol (MCP)

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 40-50 phút.
> Mục tiêu: hiểu sâu MCP để cấu hình và dùng đúng trong buổi thực hành.

---

## Mục lục

1. [Bối cảnh: vấn đề M×N](#1-bối-cảnh)
2. [Concept: MCP là gì](#2-concept)
3. [Core Components: kiến trúc 3 vai trò](#3-core-components)
4. [Hai tầng: Data Layer & Transport Layer](#4-hai-tầng)
5. [Ba primitives: Tools, Resources, Prompts](#5-ba-primitives)
6. [Vòng đời một phiên MCP](#6-vòng-đời)
7. [Features nâng cao & Roadmap 2026](#7-features-nâng-cao)
8. [Implementation: MCP trong DevOps](#8-implementation)
9. [Best Practices — đặc biệt là bảo mật](#9-best-practices)
10. [Case Study](#10-case-study)
11. [Thuật ngữ & Đọc thêm](#11-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. Vấn đề M×N

Trước MCP: mỗi ứng dụng AI muốn dùng mỗi tool đều cần một tích hợp riêng.

```
M ứng dụng AI  ×  N tool  =  M×N tích hợp phải xây và bảo trì
```

Ví dụ: 3 model × 10 tool = **30 connector** riêng biệt. Mỗi connector tự phát minh cách auth, sandbox, xử lý dữ liệu — không nhất quán, dễ lỗi.

### 1.2. MCP biến M×N thành M+N

```
Với MCP:  M ứng dụng  +  N server  =  M+N
```

Xây MCP server **một lần**, bất kỳ host tương thích nào cũng dùng được. Đây là lý do MCP được ví là **"USB-C cho AI"** — một chuẩn cắm, mọi thiết bị.

### 1.3. Vì sao MCP bùng nổ cùng lúc với Agentic AI

Agent cần một "tầng quyền tool" — danh sách những gì nó gọi được. Không có chuẩn, mỗi framework tự phát minh cách đăng ký tool. Với MCP, tầng tool của agent đơn giản là *"hợp của các MCP server tôi đang kết nối"*. Càng nhiều agent được triển khai, tích hợp bespoke càng đau → MCP càng hiển nhiên.

### 1.4. Vị thế 2026

- ~97M downloads/tháng, 200+ server implementation (tháng 3/2026).
- Tháng 12/2025: Anthropic, Block, OpenAI lập **Agentic AI Foundation** dưới Linux Foundation, đóng góp cả MCP và A2A.
- MCP giờ là chuẩn industry de facto, không còn là sản phẩm riêng của Anthropic.

---

## 2. Concept

### 2.1. Định nghĩa

> **MCP (Model Context Protocol)** là một chuẩn mở, vendor-neutral, dùng JSON-RPC 2.0, định nghĩa cách ứng dụng AI kết nối tới tool, data source và API bên ngoài — thay thế tích hợp point-to-point bằng một giao thức client-server thống nhất.

### 2.2. MCP KHÔNG phải là gì

- **Không thay thế REST API.** REST/GraphQL vẫn phục vụ client con người và service truyền thống. MCP *bọc* các API đó để LLM dùng được.
- **Không phải framework agent.** MCP chỉ lo "agent ↔ tool". Việc "agent ↔ agent" là của A2A protocol.
- **Không chứa bảo mật trong giao thức.** Bảo mật nằm ở **host** — host sở hữu user consent, credential scope, allow-list per-tool.

### 2.3. MCP vs Function Calling

MCP tool thường được implement *bằng* function calling bên dưới. Điểm MCP thêm vào: **chuẩn hóa** cách mô tả schema, cách discovery, cách invoke — để tool dùng lại được across mọi host.

---

## 3. Core Components — kiến trúc 3 vai trò

```
┌─────────────────── HOST (Claude Code / Desktop / Cursor) ──────────────────┐
│                                                                            │
│   ┌──────────┐         ┌──────────┐         ┌──────────┐                   │
│   │ Client 1 │         │ Client 2 │         │ Client 3 │                   │
│   └────┬─────┘         └────┬─────┘         └────┬─────┘                   │
│        │ 1-1                │ 1-1                │ 1-1                      │
└────────┼────────────────────┼────────────────────┼─────────────────────────┘
         │                    │                    │
   ┌─────▼─────┐        ┌──────▼─────┐       ┌──────▼──────┐
   │ Server A  │        │  Server B  │       │  Server C   │
   │ filesystem│        │ kubernetes │       │ prometheus  │
   └───────────┘        └────────────┘       └─────────────┘
```

| Vai trò | Mô tả |
|---|---|
| **Host** | Ứng dụng AI người dùng tương tác. Sở hữu LLM, quản lý nhiều client, **chịu trách nhiệm bảo mật**. |
| **Client** | Nằm trong host. Mỗi client giữ kết nối **1-1** với đúng 1 server. Là "message router": forward JSON-RPC request/response, quản lý subscription, xử lý disconnect. |
| **Server** | Tiến trình nhẹ, độc lập. Expose tool/resource/prompt. Chạy **local** (cùng máy, stdio) hoặc **remote** (qua HTTP). |

**Điểm quan trọng — security boundary:** mỗi client chỉ nói chuyện với 1 server → ngăn rò rỉ context/quyền giữa các service. Server B không thấy được dữ liệu của server A.

---

## 4. Hai tầng

MCP gồm 2 tầng tách biệt:

### 4.1. Data Layer — "nói cái gì"

Dựa trên **JSON-RPC 2.0**. Định nghĩa: lifecycle kết nối, các primitive (tools, resources, prompts), notification.

### 4.2. Transport Layer — "thông điệp đến nơi bằng cách nào"

| Transport | Cơ chế | Dùng khi |
|---|---|---|
| **stdio** | Host spawn server làm tiến trình con, giao tiếp qua stdin/stdout | Server local — nhanh, không network overhead, credentials không rời máy |
| **Streamable HTTP** | HTTP POST + Server-Sent Events. Hỗ trợ OAuth, bearer token | Server remote — dùng chung cho team, scale. Thay thế SSE transport cũ (spec 11/2025) |

Tầng transport *trừu tượng hóa* chi tiết giao tiếp — cùng một JSON-RPC payload chạy trên mọi transport. LLM không biết (và không cần biết) tool call đi tới SQLite local hay AWS Lambda remote.

**Cho khóa học: stdio.** Lý do — credentials (kubeconfig, AWS key) ở lại máy học viên, không gửi đi đâu. Đây là lựa chọn an toàn cho môi trường lab và cho production DevOps cá nhân.

---

## 5. Ba primitives

MCP cố ý chỉ có **đúng 3 primitive**. Nhiều hơn sẽ chồng chéo; ít hơn sẽ ép mọi thứ vào một khuôn.

| Primitive | Là gì | Ai điều khiển | Ví dụ DevOps |
|---|---|---|---|
| **Tools** | Hàm thực thi — agent gọi để *hành động* | **Model-controlled** — AI tự quyết khi nào gọi | `list_pods`, `get_logs`, `terraform_plan` |
| **Resources** | Nguồn dữ liệu read-only — agent *đọc* để lấy context | **Application-controlled** — host quyết khi nào đưa vào | nội dung file, schema DB, log |
| **Prompts** | Template tương tác dựng sẵn | **User-controlled** — hiện ra cho người dùng chọn | `/k8s-diagnose`, "review this PR" |

### 5.1. Tools — sâu hơn

Tool là *hành động*. Mỗi tool có schema mô tả input/output. Agent đọc schema (qua `tools/list`), quyết định gọi tool nào với tham số gì (qua `tools/call`). Đây là primitive quan trọng nhất cho DevOps.

### 5.2. Resources — sâu hơn

Resource là *dữ liệu read-only*, định danh bằng URI (vd `config://app-settings`). Resource là "xương sống" của RAG-style workflow trong MCP — thay vì nhồi tài liệu vào prompt, expose chúng làm resource để LLM yêu cầu khi cần.

### 5.3. Prompts — primitive bị đánh giá thấp nhất

Prompt chuyển việc prompt-engineering từ ứng dụng host sang server sở hữu domain. Team vận hành GitHub MCP server cũng là team biết prompt "review PR" tốt trông thế nào — họ ship nó làm prompt, mọi client đều nhận được prompt đã tinh chỉnh.

### 5.4. Discovery — `*/list`

Mỗi primitive có method discovery (`tools/list`, `resources/list`, `prompts/list`), retrieval (`*/get`), và execution (`tools/call`). Client dùng `*/list` để **tự động khám phá** primitive có sẵn — không cần prompt engineering bespoke như trước MCP.

---

## 6. Vòng đời một phiên MCP

```
1. INITIALIZE
   Client → Server:  "initialize" — gửi protocolVersion + capabilities của client
   Server → Client:  trả về capabilities của server (hỗ trợ tools? resources? prompts?)

2. CAPABILITY NEGOTIATION
   Hai bên thống nhất tính năng nào dùng được.
   ⚠️ Nếu client không advertise 1 capability → server KHÔNG được dùng tính năng đó.
      Vd: client không có "sampling" → server không gửi được sampling/createMessage.

3. DISCOVERY
   Client gọi tools/list, resources/list, prompts/list → biết server có gì.

4. OPERATION
   Request/response thông thường: tools/call, resources/get, prompts/get...
   Server có thể gửi NOTIFICATION (một chiều, không cần reply):
     - notifications/tools/list_changed — tool thay đổi
     - logging/message — log

5. SHUTDOWN
   Đóng kết nối gọn gàng.
```

**JSON-RPC 2.0** cho phép cả request (cần response) lẫn notification (không cần response). Notification giúp server "đẩy" cập nhật cho client mà không cần client hỏi liên tục — DB offline, tool mới xuất hiện → agent biết ngay.

---

## 7. Features nâng cao & Roadmap 2026

### 7.1. Sampling & Elicitation — Human-in-the-Loop

Hai primitive client expose cho server:

- **Sampling** — server xin host gọi LLM giúp (`sampling/createMessage`). Server không cần API key LLM riêng.
- **Elicitation** — server xin host hỏi người dùng một thông tin.

**Pattern thực tế:** một database migration server phát hiện thay đổi schema → dùng *Sampling* nhờ LLM phân tích tác động → nếu rủi ro cao, dùng *Elicitation* xin người dùng phê duyệt cuối. Đây là Human-in-the-Loop — cân bằng tự chủ của agent với kiểm soát của con người.

### 7.2. Roots — biên giới filesystem

Client định nghĩa "roots" — thư mục/file mà server được phép truy cập. IDE acting as host expose thư mục dự án hiện tại làm root. Đây là cơ chế giới hạn phạm vi quan trọng (sẽ áp dụng khi cấu hình filesystem MCP).

### 7.3. Tasks (Experimental) — thực thi bất đồng bộ

Hiện MCP request là synchronous. Tasks primitive cho phép thao tác dài: agent dispatch một job pipeline 20 phút, poll trạng thái — thiết yếu cho agent always-on.

### 7.4. Roadmap H2 2026

- **Stateless server operation** — server không giữ state, dễ scale.
- **Official registry** — kho server kiểu npm, host search/install/trust server qua package index chuẩn.
- **MCP Server Cards** — auto-discovery.
- **A2A maturity** — phối hợp agent-to-agent.

### 7.5. MCP vs A2A — bổ sung, không cạnh tranh

| Protocol | Định nghĩa |
|---|---|
| **MCP** | Agent ↔ tool/data |
| **A2A** (Agent-to-Agent) | Agent ↔ agent — ủy thác task, chia sẻ kết quả |

Dùng cùng nhau: agent dùng MCP truy cập tool của mình, dùng A2A ủy thác task phức tạp cho agent khác.

---

## 8. Implementation — MCP trong DevOps

### 8.1. Hai cách cài MCP server cho Claude Code

```bash
# Cách 1: lệnh đơn giản
claude mcp add <tên> -- npx -y <package>

# Cách 2: JSON đầy đủ (khi cần env var)
claude mcp add-json <tên> '{"command":"npx","args":[...],"env":{...}}' -s user

# Kiểm tra
claude mcp list      # mỗi server phải hiện ✓ Connected
```

### 8.2. `.mcp.json` — chia sẻ cấu hình

File `.mcp.json` ở thư mục dự án cho phép commit cấu trúc cấu hình MCP vào Git (chia sẻ với team). **Lưu ý:** chỉ commit cấu trúc, KHÔNG commit credentials — credentials để ở biến môi trường.

### 8.3. MCP server DevOps quan trọng

| Server | Dùng cho | Lưu ý |
|---|---|---|
| `filesystem` | Đọc config, repo file | Giới hạn allow-list path |
| `kubernetes-mcp-server` (containers/) | Pod, deployment, log, Helm | Có cờ `--read-only`, secrets masking, `/k8s-diagnose` |
| `docker` MCP | Container inspect, log, stats | Qua Docker MCP Toolkit hoặc npx |
| `terraform-mcp-server` (HashiCorp) | Query registry, sinh module | Giảm hallucination về resource |
| `prometheus` MCP | PromQL bằng natural language | Chuẩn bị cho Day 4 |
| `aws` MCP (official) | Lambda, ECS, EKS, S3, RDS | Dùng IAM read-only |

### 8.4. Debug MCP server

Dùng **MCP Inspector**: `npx @modelcontextprotocol/inspector` — UI để list tool, test invocation, soi JSON-RPC traffic mà không cần LLM.

---

## 9. Best Practices — bảo mật là trọng tâm

### 9.1. Least-privilege — nguyên tắc quan trọng nhất

> **MCP server kế thừa quyền của bạn. Nếu kubeconfig của bạn là cluster-admin, thì Claude cũng là cluster-admin.**

Phòng vệ:
- **Kubernetes:** ServiceAccount riêng + ClusterRole **read-only**, kubeconfig riêng cho MCP. Dùng cờ `--read-only`.
- **AWS:** IAM user `mcp-readonly` với policy `ReadOnlyAccess`.
- Blast radius bị giới hạn bởi **RBAC**, không phải bởi "thiện chí" của MCP server. Kể cả Claude hiểu sai prompt, RBAC vẫn chặn.

### 9.2. Context pinning

Rủi ro thật: bạn bảo "xóa pod kẹt ở staging", agent chạy nhầm context `production`. **Luôn pin context cụ thể** trong cấu hình MCP server.

### 9.3. Credentials stay local

Với stdio, MCP server chạy trên máy bạn, dùng credentials của bạn. LLM chỉ nhận **kết quả tool call** — không nhận credentials. Đây là lý do stdio an toàn cho DevOps cá nhân.

### 9.4. Allow-list cho filesystem

Filesystem MCP chỉ cấp đúng thư mục cần (qua roots), không cấp `/`.

### 9.5. Capability negotiation đúng

Server chỉ dùng tính năng client đã advertise. Server tự ý gửi notification cho capability chưa advertise = sai protocol.

### 9.6. Pin version

Pin version MCP server trong `.mcp.json` — tránh package update giữa chừng làm break workflow.

---

## 10. Case Study

### 10.1. Debug InsightHub qua MCP — bài Day 2

**Before MCP:** debug pod InsightHub crash — `kubectl get pods` → `kubectl describe` → `kubectl logs` → đọc → suy luận. ~25 phút, nhiều lần chuyển ngữ cảnh.

**After MCP:** hỏi Claude Code một câu — *"Service nào của InsightHub đang lỗi? Lấy log và tóm tắt nguyên nhân gốc."* Claude gọi Kubernetes MCP + Docker MCP, đọc log, correlate, trả RCA. ~45 giây.

Khác biệt không nằm ở việc Claude thông minh hơn người — mà ở chỗ Claude **kết nối được** vào cluster, và **tự động khám phá** được tool nào dùng để làm gì.

### 10.2. Bài học từ ngành — giảm bề mặt tích hợp

Một công ty (AutoBlogging.Pro) báo cáo: kiến trúc MCP-native giảm bề mặt tích hợp từ **47 custom adapter xuống 6 MCP server**. Đây là minh họa cụ thể của M×N → M+N: mỗi lần model mới ra, không phải refactor 47 adapter, chỉ cần 6 server tương thích sẵn.

### 10.3. Vì sao InsightHub là RAG app lại liên quan MCP

InsightHub bản thân là một RAG Notebook. Resources primitive của MCP chính là "xương sống của RAG-style workflow" — thay vì nhồi tài liệu vào prompt, expose làm resource. Học viên sẽ thấy: tư duy MCP và tư duy RAG cùng chung một gốc — *quản lý context cho LLM một cách có cấu trúc*.

---

## 11. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **MCP** — Model Context Protocol.
- **Host / Client / Server** — 3 vai trò kiến trúc MCP.
- **JSON-RPC 2.0** — giao thức RPC nền của MCP.
- **stdio / Streamable HTTP** — hai transport.
- **Primitive** — Tools / Resources / Prompts.
- **Capability negotiation** — hai bên thống nhất tính năng lúc initialize.
- **Sampling / Elicitation** — primitive client expose cho server (Human-in-the-Loop).
- **Roots** — biên giới filesystem client cấp cho server.
- **A2A** — Agent-to-Agent protocol, bổ sung cho MCP.
- **Least-privilege** — chỉ cấp quyền tối thiểu cần thiết.

### Đọc thêm (khuyến nghị trước buổi)

- modelcontextprotocol.io — Architecture overview (trang chính thức).
- Repo `containers/kubernetes-mcp-server` — getting started Claude Code.

### Tự kiểm tra trước khi đến lớp

1. Vấn đề M×N là gì? MCP giải nó ra sao?
2. 3 vai trò Host / Client / Server — vai trò nào chịu trách nhiệm bảo mật?
3. stdio khác Streamable HTTP thế nào? Vì sao khóa học chọn stdio?
4. 3 primitive — cái nào model-controlled, cái nào user-controlled?
5. "MCP server kế thừa quyền của bạn" nghĩa là gì? Phòng vệ thế nào?
6. Sampling và Elicitation phục vụ pattern gì?

---

*Pre-reading Day 2 — Module 7 AI-Native DevOps.*
