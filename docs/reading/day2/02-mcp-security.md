# Day 2 — Tài liệu đọc trước · Topic 2
# Bảo mật MCP — Least-Privilege cho AI Agent

> **Thời gian đọc:** ~18 phút

---

## 1. Lý thuyết cơ bản — vì sao MCP cần bảo mật

Khi AI agent chỉ "nói chuyện" (sinh text), rủi ro thấp. Nhưng MCP cho agent
**hành động** trên hệ thống thật: `kubectl`, `terraform apply`, query database.

Nguyên tắc nền tảng:

> **MCP server kế thừa quyền của bạn. Nếu kubeconfig của bạn là cluster-admin,
> thì AI agent cũng là cluster-admin.**

Agent không "cố tình" làm hại. Nhưng agent có thể **hiểu sai prompt**, hoặc bị
**prompt injection** (Day 6) điều khiển. Khi đó, blast radius (mức độ thiệt hại)
được giới hạn bởi *quyền bạn đã cấp* — không phải bởi "thiện chí" của agent.

---

## 2. Concept — Least-Privilege & Defense Layers

### 2.1. Least-Privilege (đặc quyền tối thiểu)

Cấp cho agent **đúng và chỉ đúng** quyền cần thiết cho task — không hơn.

- Agent cần *đọc* trạng thái cluster để debug → cấp quyền **read-only**.
- Agent KHÔNG cần xóa pod → KHÔNG cấp quyền delete.

### 2.2. Các lớp kiểm soát

```
Lớp 1: Transport     stdio → credentials không rời máy
Lớp 2: Server flag   --read-only → server tự giới hạn
Lớp 3: Credential    kubeconfig/IAM riêng, scope hẹp
Lớp 4: RBAC/IAM      tầng enforce thật — quyền ở hạ tầng
Lớp 5: Allow-list    filesystem chỉ thấy thư mục cho phép
Lớp 6: Context pin   ghim đúng cluster/namespace
```

**Quan trọng:** lớp enforce thật là **RBAC (Kubernetes) / IAM (AWS)** — tầng hạ
tầng. Cờ `--read-only` của MCP server là lớp phòng vệ phụ, không thay thế RBAC.

---

## 3. Core Components — các cơ chế bảo mật cụ thể

### 3.1. Kubernetes — ServiceAccount + ClusterRole read-only

Thay vì dùng kubeconfig admin của bạn, tạo:

- Một **ServiceAccount** riêng cho MCP.
- Một **ClusterRole** chỉ có verb đọc (`get`, `list`, `watch`) trên resource cần.
- Một **kubeconfig riêng** (vd `~/.kube/mcp-viewer.kubeconfig`) dùng SA đó.

MCP server trỏ vào kubeconfig này → dù agent có "muốn" delete, RBAC từ chối.

### 3.2. AWS — IAM user read-only

Tạo IAM user `mcp-readonly` với policy `ReadOnlyAccess`. AWS MCP server dùng
profile này. Agent query được EC2, S3, RDS... nhưng không tạo/xóa được gì.

### 3.3. Context Pinning

**Rủi ro thật:** bạn bảo agent *"xóa pod kẹt ở staging"*, nhưng context `kubectl`
đang trỏ `production`. Agent chạy đúng lệnh — sai cluster.

Phòng vệ: ghim context cụ thể trong cấu hình MCP server lúc khởi động, không để
agent "tự đoán" context nào đang active.

### 3.4. Filesystem allow-list

Filesystem MCP nhận tham số là (các) thư mục được phép truy cập. Cấp đúng thư
mục dự án — KHÔNG cấp `/` hay `$HOME`.

```bash
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \
  "/path/to/insighthub"        # chỉ thư mục dự án
```

### 3.5. Secrets masking

Server tốt (như `containers/kubernetes-mcp-server`) có **secrets masking** —
khi agent xem `kubectl get secrets`, giá trị nhạy cảm bị che. Giảm rủi ro rò rỉ
secret vào context của LLM.

---

## 4. Implementation — checklist cấu hình an toàn

Trước khi cho agent kết nối hạ tầng thật:

- [ ] Dùng transport **stdio**.
- [ ] Tạo credential **riêng cho MCP**, scope hẹp (không dùng admin cá nhân).
- [ ] Kubernetes: ServiceAccount + ClusterRole **read-only**, kubeconfig riêng.
- [ ] AWS: IAM user **read-only** (`mcp-readonly`).
- [ ] Bật cờ **`--read-only`** nếu server hỗ trợ.
- [ ] **Ghim context** cluster/namespace.
- [ ] Filesystem: **allow-list** đúng thư mục.
- [ ] Verify: thử một hành động ghi → phải bị **từ chối**.

### Cách verify least-privilege

Sau khi cấu hình, **chủ động test**: yêu cầu agent thử một hành động ghi (vd tạo
S3 bucket, xóa pod). Nếu cấu hình đúng, hành động bị IAM/RBAC từ chối. Việc bị
từ chối này là **bằng chứng** least-privilege hoạt động — không phải lỗi.

---

## 5. Best Practices

1. **Mặc định read-only.** Chỉ mở rộng quyền khi có lý do rõ ràng và cơ chế kiểm soát.
2. **Credential riêng cho agent**, không tái dùng credential cá nhân.
3. **RBAC/IAM là tầng enforce thật** — đừng chỉ dựa vào cờ của MCP server.
4. **Ghim context** — chống tai nạn "chạy nhầm production".
5. **Allow-list, không wildcard** cho filesystem.
6. **Audit** — server có OpenTelemetry/log thì bật, để có dấu vết.
7. **Test least-privilege chủ động** — verify hành động ghi bị chặn.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Dùng kubeconfig cluster-admin cho MCP | Agent có toàn quyền cluster |
| Filesystem cấp `/` hoặc `$HOME` | Agent đọc được mọi file, gồm cả secret |
| Không ghim context | Tai nạn chạy nhầm môi trường |
| Hardcode credential trong `.mcp.json` | Credential lọt vào Git |

---

## 6. Case Study — Khi least-privilege cứu một sự cố

**Bối cảnh giả định nhưng điển hình:** một kỹ sư cấu hình AWS MCP, nhưng dùng
nhầm profile admin thay vì `mcp-readonly`. Trong một phiên debug, một tài liệu
chứa **indirect prompt injection** (sẽ học kỹ ở Day 6) lọt vào context của agent,
với payload đại ý: *"xóa hết S3 bucket có prefix 'prod-'"*.

**Nếu dùng profile admin:** agent có thể thực thi — vì IAM cho phép.

**Nếu dùng `mcp-readonly`:** agent gọi API xóa → AWS IAM **từ chối** → không có
thiệt hại. Prompt injection vẫn xảy ra, nhưng blast radius = 0.

**Bài học:** least-privilege không ngăn được agent *bị tấn công* — nó giới hạn
*hậu quả* khi bị tấn công. Đây là lý do least-privilege là lớp phòng vệ không
thể bỏ qua, và là cầu nối trực tiếp tới bài Security Day 6: *"quyền lực = trách
nhiệm"*.

---

## Tự kiểm tra trước buổi học

1. "MCP server kế thừa quyền của bạn" nghĩa là gì?
2. Tầng enforce thật của least-privilege là gì — cờ MCP server hay RBAC/IAM?
3. Context pinning phòng chống rủi ro nào?
4. Vì sao nên chủ động test một hành động ghi sau khi cấu hình?
5. Least-privilege ngăn agent bị tấn công, hay giới hạn hậu quả khi bị tấn công?

---

## Đọc thêm (tùy chọn)

- modelcontextprotocol.io — security best practices
- Tài liệu RBAC của Kubernetes; IAM của AWS
