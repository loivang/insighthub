# InsightHub — Student FAQ

> Câu hỏi thường gặp + cách fix. Tham khảo khi gặp lỗi trước khi hỏi Slack.

---

## 🚀 Setup / Pre-class

### Q: `docker compose up` báo "port 8000 already in use"

Có service khác đang chạy port 8000.

```bash
# Tìm process chiếm port
lsof -i :8000          # macOS/Linux
netstat -ano | findstr :8000   # Windows

# Hoặc đổi port InsightHub trong docker-compose.yml:
#   "8001:8000"
```

### Q: `pgvector extension not found` sau `docker compose up`

Postgres volume cũ còn schema chưa migrate.

```bash
docker compose down -v       # xóa volume
docker compose up --build    # init lại từ infra/db/init.sql
```

### Q: `EMBEDDING_DIM` mismatch error

Embedding dim trong code phải khớp `VECTOR(n)` trong DB schema.

```bash
# Check .env
grep EMBEDDING_DIM .env       # vd: 1024

# Check schema
grep VECTOR infra/db/init.sql # vd: VECTOR(1024)

# Phải giống nhau. Đổi 1 chỗ → đổi cả 2 + recreate DB.
```

### Q: `claude` command not found

```bash
# Check Node 20+
node -v   # → v20.0.0+

# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Login (browser-based OAuth)
claude login
```

### Q: `claude login` redirects vô hạn

- Đảm bảo trình duyệt mặc định mở được.
- Tắt VPN/proxy nếu có.
- Thử: `claude config set --global apiKey "sk-ant-..."` (manual key)

### Q: Smoke test PASS 4/6 — Web hoặc Chat lỗi

- **Web FAIL** thường do `npm install` build slow lần đầu — `docker compose logs -f web` để xem.
- **Chat FAIL** thường do chưa có document ingested → upload trước rồi chat sau.

---

## 🤖 Day 1 — AI Coding Agents

### Q: Agent loop forever, không dừng

```bash
# Trong Claude Code
> /clear

# Hoặc start with max-turns limit
claude --max-turns 20

# Hoặc rephrase prompt rõ hơn — agent đang đoán mò
```

### Q: Refactor xong nhưng `docker compose up` lỗi worker

Triệu chứng phổ biến:
1. **`ModuleNotFoundError: arq`** → thêm `arq`, `psycopg2-binary`, `pgvector`, `voyageai` vào `ingestion-worker/requirements.txt`
2. **"event loop already running"** → wrap sync function `process_document` trong `asyncio.run_in_executor`:
   ```python
   loop = asyncio.get_event_loop()
   await loop.run_in_executor(None, process_document, doc_id, filename, content)
   ```
3. **Worker không nhận job** → cả api và worker phải dùng cùng `REDIS_URL=redis://redis:6379`
4. **API vẫn block khi upload** → check `api/app/routers/documents.py` — đã đổi `ingest_document_sync(...)` thành `await redis.enqueue_job(...)` chưa?

### Q: CLAUDE.md có nên dài không?

**Không**. Quy tắc: **≤ 200 dòng**. Agent ignore phần giữa khi quá dài.

Cô đọng:
- Architecture: 5-10 dòng
- Conventions: 5-10 dòng
- Commands: 5 dòng (build/test/lint/run/migration)
- Constraints: 5-10 dòng (forbidden patterns)
- Domain knowledge: 10-20 dòng
- References: 3-5 dòng

### Q: `/cost` báo $5+ trong 1 session — bị bill shock?

```bash
# Stop ngay
> /clear

# Phòng vệ:
- `/clear` giữa các task khác nhau
- CLAUDE.md cô đọng ≤ 200 dòng
- Set Anthropic Console spend limit $50/month
- Day 6 sẽ setup LiteLLM gateway với hard cap
```

---

## 🔌 Day 2 — MCP Protocol

### Q: `claude mcp list` báo `❌ Failed to connect`

Debug bằng MCP Inspector — không cần LLM:

```bash
npx @modelcontextprotocol/inspector \
  npx -y kubernetes-mcp-server@1.0

# Browser http://localhost:6274
# Click "List Tools" — nếu empty → server không expose tools
# Check stderr trong Inspector terminal
```

Common errors:
- `unable to load kubeconfig` → set `KUBECONFIG` env var trong `.mcp.json`
- `Forbidden: cannot list pods` → ClusterRoleBinding RBAC issue
- `Module not found` → npm version syntax sai (`@1.0` không phải `@1`)

### Q: K8s MCP `Forbidden: cannot list pods` mặc dù đã apply RBAC

```bash
# Verify ServiceAccount + RBAC
kubectl get sa mcp-readonly -n insighthub
kubectl get clusterrolebinding mcp-readonly

# Test bằng kubectl auth
kubectl auth can-i get pods \
  --as=system:serviceaccount:insighthub:mcp-readonly
# → "yes" expected

# Nếu "no" → recreate ClusterRoleBinding
```

### Q: `.mcp.json` `Bash` permission denied khi run npm

Không cần Bash permission cho MCP. Cấu hình stdio:

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "npx",     // không phải "bash"
      "args": ["-y", "kubernetes-mcp-server@1.0"]
    }
  }
}
```

---

## 🏗️ Day 3 — IaC + Pipeline

### Q: `terraform init` báo "Backend not found" cho S3

Chicken-and-egg: backend cần S3 + DynamoDB tồn tại trước.

```bash
# Option A: Tạo manual lần đầu
aws s3 mb s3://insighthub-tfstate-<your-id>
aws dynamodb create-table \
  --table-name insighthub-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Option B: Bootstrap module riêng với backend "local" trước
```

### Q: `checkov` báo 20+ HIGH severity

Đừng panic. **Fix theo nhóm**, không từng lỗi một.

```bash
# Group findings
checkov -d infra/ --output cli | grep "FAILED" | sort | uniq -c

# Trong Claude Code
> "Đây là 12 finding HIGH từ checkov. Group theo loại + sinh patch cho từng group:
   - CKV_AWS_16 (3 instances): RDS encryption
   - CKV_AWS_24 (2 instances): SG 0.0.0.0/0
   - ..."
```

### Q: OIDC AWS `Could not assume role`

Check trust policy `sub:` claim phải match `repo:OWNER/REPO:*`:

```json
"Condition": {
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:USERNAME/insighthub:*"
  }
}
```

### Q: pgvector RDS missing extension

RDS dùng custom parameter group:

```hcl
resource "aws_db_parameter_group" "pgvector" {
  family = "postgres16"
  parameter {
    name  = "shared_preload_libraries"
    value = "vector"
    apply_method = "pending-reboot"
  }
}
```

Restart RDS instance sau khi apply.

---

## 📊 Day 4 — AIOps

### Q: Prometheus targets DOWN (`up == 0`)

```bash
# Check pod label
kubectl get pods -n insighthub --show-labels
# ServiceMonitor selector phải match

# Check Service port name
kubectl get svc -n insighthub -o yaml | grep -A2 ports:
# ServiceMonitor `port: http` phải match Service port name "http"
```

### Q: Anomaly rules không fire dù inject lỗi

Cần baseline data trước. Lab 5-10 phút minimum; production 7 ngày.

```bash
# Force baseline reset
kubectl delete prometheusrule insighthub-anomaly -n monitoring
kubectl apply -f observability/anomaly-rules.yaml

# Wait 30 phút accumulate data trước khi inject incident
```

### Q: AI RCA hallucinate metric không có thật

Prompt cần "evidence-first" pattern:

```
Output JSON. For every hypothesis, MUST cite:
- Metric name (must exist in Prometheus)
- Value at timestamp
- Source (Prometheus query or K8s event)
Do NOT propose hypothesis without evidence.
```

### Q: Grafana dashboard "No data"

```bash
# Check Prometheus data source
# Grafana → Configuration → Data Sources → Prometheus
# URL: http://kube-prom-stack-prometheus.monitoring.svc:9090

# Test query trực tiếp Prometheus UI trước
kubectl port-forward -n monitoring svc/kube-prom-stack-prometheus 9090:9090
# Browser http://localhost:9090 → Graph → query
```

---

## 💬 Day 5 — ChatOps

### Q: Slack bot reply nhưng không thấy event

```bash
# Verify Event Subscriptions Request URL = ngrok URL + /slack/events
# Slack App → Event Subscriptions → "Verified" ✓

# Subscribe bot events:
#   - app_mention
#   - message.im

# Reinstall app to workspace after scope changes
```

### Q: Bot timeout 3s — Slack báo "request URL failed"

LLM call + MCP call > 3s. Dùng BackgroundTasks:

```python
@app.post("/slack/events")
async def slack_events(request: Request, background: BackgroundTasks):
    body = await request.json()
    # Verify signature (fast)
    # ...
    # Background process (LLM + MCP)
    background.add_task(handle_question, body["event"])
    # Return 200 IMMEDIATELY
    return {"ok": True}
```

### Q: Signature mismatch dù secret đúng

Body parsing issue. **Đọc raw body trước**, parse JSON sau:

```python
body_bytes = await request.body()         # raw bytes
# Verify with body_bytes
signature_ok = verify_signature(body_bytes, ...)
# Then parse
body = json.loads(body_bytes)
```

### Q: ngrok URL đổi sau mỗi restart

Free tier sinh URL random. Tùy chọn:
1. Pay $8/month cho stable URL: `ngrok http 8080 --domain=insighthub-bot.ngrok.app`
2. Sau mỗi restart → update Slack Event URL
3. Cloudflare Tunnel (free + stable subdomain)

---

## 🔒 Day 6 — Security + FinOps

### Q: Promptfoo scan 20+ HIGH initially — overwhelming

Đây là **expected**! InsightHub v0 vulnerable to nhiều thứ.

Fix incrementally:
1. **Layer 1**: Input sanitization (strip Unicode invisible)
2. **Layer 2**: Prompt hardening (delimiters `<context>`)
3. **Layer 3**: Guardrails (Bedrock/NeMo)
4. **Layer 4**: Output validation (Pydantic schema)
5. **Layer 5**: Audit log
6. **Layer 6**: Continuous red team

Mỗi layer → re-run Promptfoo → giảm dần findings.

### Q: Indirect injection vẫn pass sau khi sanitize

Có thể vẫn còn Unicode invisible chars chưa cover:

```python
HIDDEN_UNICODE = [
    '​',  # zero-width space
    '‌',  # zero-width non-joiner
    '‍',  # zero-width joiner
    '﻿',  # zero-width no-break space
    '‮',  # right-to-left override
    # ... thêm patterns
]
```

Hoặc add layer 3: Bedrock Guardrails PROMPT_ATTACK filter.

### Q: LiteLLM gateway không enforce budget

Cần Postgres DB (SQLite has issues with concurrent writes):

```yaml
general_settings:
  database_url: postgres://...    # NOT sqlite:///
```

Restart proxy sau khi đổi.

### Q: Cost vọt dù có gateway

Check:
1. App có route qua gateway không? `grep ANTHROPIC_BASE_URL .env`
2. Virtual key có `max_budget`?
3. Routing rules đúng? Haiku cho simple tasks?

```bash
curl http://litellm:4000/key/info \
  -H "Authorization: Bearer $LITELLM_VIRTUAL_KEY"
```

---

## 🚢 Day 7 — Showcase

### Q: Demo live fail trên classroom network

Plan B: Loom backup recording. Plan C: screenshot slides.

```bash
# Record full 12' demo trước Day 7
# Tool: Loom (free), OBS, Screen Studio
```

### Q: Q&A khó — tôi không nhớ "vì sao chọn ARQ"?

OK to say "I considered X and Y but chose Z because [reason]". Better than vibe answer.

Notes preparation:
- Top 5 architectural decisions made
- Trade-offs cho mỗi quyết định
- Alternatives considered

### Q: Tôi chưa hoàn thiện đủ artifact — có pass không?

Pass = ≥ 70/100 tổng + ≥ 5/7 daily artifact + ≥ 80% attendance.

Nếu thiếu 1 Day → có thể bù bằng excellence ở các Day khác. Trao đổi với trainer nếu lo.

---

## 🆘 Hỏi ai khi gặp vấn đề?

| Vấn đề | Channel/Resource |
|---|---|
| Setup / config | Slack `#help` |
| Lab-specific | Slack `#day-{N}-help` |
| Hỏi rubric / grading | DM trainer |
| Hỏi nội dung syllabus | Slack `#general` hoặc DM trainer |
| Cảm thấy quá tải | DM trainer (real concern, không phán đoán) |
| Bug trong InsightHub starter | Slack `#bug-report` (sửa cho cohort sau) |

---

*Student FAQ v3.0 · InsightHub · Module 7 AI-Native DevOps · Tháng 5/2026*
