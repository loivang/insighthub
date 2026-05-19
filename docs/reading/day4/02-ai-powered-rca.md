# Day 4 — Tài liệu đọc trước · Topic 2
# AI-Powered Root Cause Analysis (RCA)

> **Thời gian đọc:** ~18 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Root Cause Analysis là gì

RCA = quá trình tìm **nguyên nhân gốc** của một sự cố, không chỉ triệu chứng.

- Triệu chứng: "trang web chậm".
- Nguyên nhân gốc: "connection pool của database cạn vì một query thiếu index".

Sửa triệu chứng (restart service) → sự cố quay lại. Sửa nguyên nhân gốc (thêm
index) → giải quyết tận gốc.

### 1.2. RCA thủ công khó ở đâu

Khi sự cố xảy ra, kỹ sư phải: mở nhiều dashboard, đọc log nhiều service, ghép
nối mốc thời gian, suy luận quan hệ nhân-quả. Dưới áp lực (sự cố production lúc
2h sáng), việc này chậm và dễ sai. **MTTR** (Mean Time To Resolution) cao.

### 1.3. AI thay đổi RCA thế nào

AI agent có thể: quét song song metrics + logs + traces, correlate các tín hiệu
theo thời gian, nhận diện pattern (memory leak, connection exhaustion...), và
tóm tắt thành RCA report bằng ngôn ngữ tự nhiên — trong vài giây thay vì vài chục
phút. Mục tiêu cuối: **giảm MTTR**.

---

## 2. Concept & Core Components

### 2.1. Pipeline AI RCA

```
Anomaly phát hiện → AI thu thập tín hiệu liên quan (metrics/logs/traces
trong cửa sổ sự cố) → correlate → nhận diện pattern → RCA report
```

### 2.2. Knowledge graph

Nền tảng AIOps hiện đại (Grafana SRE agent / Sift) dùng **knowledge graph** —
biểu đồ liên kết các thực thể (service, pod, deployment, dependency). Khi một
service lỗi, knowledge graph cho AI biết service nào *phụ thuộc* vào nó, *bị ảnh
hưởng* bởi nó — giúp correlate chính xác hơn.

### 2.3. Vai trò của MCP trong RCA

Ở Day 2 ta đã cấu hình **Prometheus MCP**. Đây chính là cầu nối: agent dùng
Prometheus MCP để query metrics bằng natural language, dùng Kubernetes MCP để
lấy log/trạng thái pod — rồi tự tổng hợp RCA. MCP biến RCA từ "agent suy đoán"
thành "agent điều tra dựa trên dữ liệu thật".

---

## 3. Features — một RCA report tốt gồm gì

| Phần | Nội dung |
|---|---|
| **Triệu chứng** | Hiện tượng quan sát được (latency tăng, error burst...) |
| **Bằng chứng** | Metric/log cụ thể chứng minh — có số liệu, có mốc thời gian |
| **Nguyên nhân gốc** | Giải thích quan hệ nhân-quả |
| **Phạm vi ảnh hưởng** | Service/người dùng nào bị tác động |
| **Đề xuất xử lý** | Hành động khắc phục — ngắn hạn & dài hạn |

Một RCA report tốt phải **dẫn chứng được** — không phải phỏng đoán. Mỗi khẳng
định cần một metric/log đi kèm.

---

## 4. Implementation — làm RCA với AI cho InsightHub

### 4.1. Các kịch bản sự cố điển hình của InsightHub

InsightHub có những điểm "dễ hỏng" tự nhiên — và đó là điểm tốt để học RCA:

| Kịch bản | Triệu chứng | Nguyên nhân gốc điển hình |
|---|---|---|
| LLM latency spike | `llm_call_latency` p95 tăng vọt | LLM provider chậm / rate limit |
| Ingestion queue dồn | `ingestion_queue_depth` tăng không giảm | Worker dừng / embedding API lỗi |
| Error burst | `rag_query_latency` lỗi tăng | DB connection sai / pgvector down |

### 4.2. Prompt RCA mẫu

```
InsightHub đang có bất thường. Dùng Prometheus MCP query các metric RED
trong 30 phút qua. Xác định:
- Triệu chứng (metric nào lệch baseline)
- Bằng chứng (số liệu cụ thể + mốc thời gian)
- Service nào bị ảnh hưởng
- Nguyên nhân gốc khả dĩ nhất
- Đề xuất xử lý ngắn hạn và dài hạn
Viết RCA report ngắn gọn.
```

### 4.3. Đánh giá RCA report của AI

AI rất giỏi correlate và tóm tắt — nhưng **không phải lúc nào cũng đúng**. Kỹ sư
cần:

- Kiểm tra bằng chứng AI đưa ra có thật không (mở metric đối chiếu).
- Đặt câu hỏi nếu nguyên nhân nghe không hợp lý.
- AI có thể đưa ra nguyên nhân *trông hợp lý* nhưng sai — giống "trust-then-verify
  gap" ở Day 1.

---

## 5. Best Practices

1. **RCA phải dẫn chứng** — mỗi khẳng định có metric/log đi kèm.
2. **Phân biệt triệu chứng và nguyên nhân gốc** — sửa gốc, không sửa triệu chứng.
3. **AI correlate, người verify** — kiểm tra bằng chứng AI đưa ra.
4. **Dùng MCP để RCA dựa trên dữ liệu thật**, không để agent suy đoán suông.
5. **Lưu RCA report** — thành runbook cho sự cố tương tự sau này.
6. **Đề xuất cả ngắn hạn và dài hạn** — vá nhanh để hết cháy, sửa gốc để không lặp lại.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Tin RCA của AI mà không verify | Sửa sai chỗ, sự cố lặp lại |
| Chỉ sửa triệu chứng | Sự cố quay lại sau ít lâu |
| RCA không dẫn chứng | Không thể tin, không thể học lại |
| Không lưu RCA | Mỗi lần sự cố lại điều tra từ đầu |

---

## 6. Case Study — RCA: 30 phút thủ công vs 30 giây với AI

**Bối cảnh:** InsightHub bất ngờ trả lời chậm. Người dùng phàn nàn. On-call vào cuộc.

### Cách thủ công

1. Mở Grafana, thấy `rag_query_latency` p95 tăng từ 2s lên 18s.
2. Không rõ chậm ở khâu nào — retrieval hay generation?
3. Mở dashboard khác: `llm_call_latency` — vẫn bình thường (~3s).
4. Vậy không phải LLM. Kiểm tra database.
5. Mở log của `api` — thấy nhiều dòng "connection pool timeout".
6. Kiểm tra Postgres — connection gần đầy.
7. Suy luận: có gì đó giữ connection quá lâu.
8. Tìm ra: một query retrieval thiếu điều kiện, quét toàn bảng.

→ ~30 phút, qua nhiều dashboard, dưới áp lực.

### Cách AI-augmented

```
> InsightHub trả lời chậm. Dùng Prometheus MCP + Kubernetes MCP điều tra,
  cho tôi RCA report có dẫn chứng.
```

Agent: query `rag_query_latency` (p95 = 18s, lệch baseline 2s) → query
`llm_call_latency` (bình thường, ~3s → loại trừ LLM) → lấy log `api` (phát hiện
"connection pool timeout") → kiểm tra Postgres metrics (connection gần đầy) →
tổng hợp:

> **Triệu chứng:** RAG latency p95 18s (baseline 2s).
> **Bằng chứng:** LLM latency bình thường (~3s) → không phải LLM. Log `api` có
> "connection pool timeout". Postgres connection 95/100.
> **Nguyên nhân gốc:** connection pool DB cạn — connection bị giữ quá lâu.
> **Đề xuất:** ngắn hạn — tăng pool size + restart `api`; dài hạn — rà soát query
> retrieval giữ connection lâu.

→ ~30 giây.

**Bài học:** AI không "đoán giỏi hơn" — nó **correlate nhanh hơn** nhiều. Việc
loại trừ LLM (bước quan trọng nhất) mà con người mất vài phút, agent làm tức
thì. Nhưng lưu ý: kỹ sư vẫn phải **verify** — mở Postgres metric đối chiếu, xác
nhận đúng connection gần đầy, trước khi hành động. AI rút ngắn MTTR, không thay
thế phán đoán kỹ sư.

---

## Tự kiểm tra trước buổi học

1. Phân biệt triệu chứng và nguyên nhân gốc. Cho ví dụ.
2. MTTR là gì? AI RCA giúp giảm MTTR thế nào?
3. Knowledge graph hỗ trợ correlate ra sao?
4. Một RCA report tốt gồm những phần nào?
5. Vì sao vẫn phải verify RCA của AI?

---

## Đọc thêm (tùy chọn)

- Grafana — Sift / SRE agent investigations
- Google SRE Book — chương Effective Troubleshooting
