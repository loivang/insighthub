# Lab Guide — Day 4: AIOps — Observability & Anomaly Detection

> **Module 7 — AI-Native DevOps** · Pillar B: Operate with AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 4, học viên có thể:

1. Phân biệt 3 thế hệ AIOps và các thuật toán anomaly detection.
2. Instrument InsightHub với Prometheus, expose metrics có ý nghĩa vận hành.
3. Triển khai anomaly detection (PromQL-based hoặc Grafana ML) trên metrics InsightHub.
4. Dùng AI để làm Root Cause Analysis (RCA) cho 1 incident.

**Daily Artifact:** Grafana dashboard cho InsightHub + anomaly alert config + 1 AI RCA report cho incident inject.

---

## Chuẩn bị trước buổi

- [ ] InsightHub live trên K8s (từ Day 3)
- [ ] Grafana Cloud free account đã tạo
- [ ] `kube-prometheus-stack` chạy trên cluster
- [ ] Đã đọc bài AI anomaly detection 2026

---

## Segment 1 — Recap & Hook (10 phút)

- Day 1-3 đã *Develop*. Từ hôm nay sang trụ cột *Operate*.
- "Alert dựa threshold cố định đã chết. Hệ thống có seasonality — Monday error spike là bình thường, threshold tĩnh sẽ báo động giả. AIOps học baseline động."
- Hook: InsightHub có 2 thứ rất "đẹp" để observe — LLM latency (dễ spike) và ingestion queue depth (dễ dồn ứ). Hôm nay ta khai thác chúng.

---

## Segment 2 — Concept: AIOps & Anomaly Detection (40 phút)

### 2.1. Ba thế hệ AIOps

| Thế hệ | Cách hoạt động | Hạn chế |
|---|---|---|
| **Gen 1 — Rule-based** | Threshold tĩnh: CPU > 80% → alert | Báo động giả với hệ có seasonality |
| **Gen 2 — ML anomaly** | Học baseline, alert khi lệch baseline | Cần training data, vẫn cần người phân tích |
| **Gen 3 — Agentic AIOps** | AI tự RCA, đề xuất fix, đôi khi tự sửa | Cần guardrails (Day 6) |

### 2.2. Thuật toán anomaly detection

| Nhóm | Thuật toán | Phù hợp |
|---|---|---|
| Statistical | z-score, IQR, MAD | Metric phân phối chuẩn, nhanh |
| Time-series | Prophet, ARIMA | Metric có seasonality rõ |
| Tree-based | Isolation Forest, Random Cut Forest | Streaming, high-cardinality |
| Deep learning | LSTM | Pattern phức tạp, cần nhiều data |

**Quy tắc chọn:** bắt đầu statistical (đơn giản, đủ tốt), chỉ lên ML khi statistical không đủ.

### 2.3. Correlation > Detection

Phát hiện anomaly là bước 1. Giá trị thật là **correlate** nhiều anomaly để ra root cause. Grafana Sift / SRE agent dùng knowledge graph để làm việc này.

### 2.4. "Model as a service" — góc nhìn DevOps về MLOps (5 phút)

DevOps engineer KHÔNG train model. Nhưng phải biết: model là 1 service — có version, có latency, có cost, cần monitor, cần rollback. Đó là toàn bộ "MLOps" mà DevOps cần. Phần train/tune model là việc của ML engineer.

---

## Segment 3 — Best Practice (30 phút)

### 3.1. Tránh anomaly noise

- Cần baseline 3-7 ngày data trước khi bật alert.
- False positive = cơ hội tinh chỉnh, không phải bỏ qua.
- Document "anomaly mong đợi" (vd: traffic tăng giờ hành chính).

### 3.2. Metrics có ý nghĩa cho InsightHub

InsightHub đã expose sẵn (file `api/app/core/metrics.py`):

| Metric | Vì sao quan trọng |
|---|---|
| `insighthub_rag_query_latency_seconds` | Trải nghiệm người dùng |
| `insighthub_llm_call_latency_seconds` | Tách riêng — dễ inject spike để học |
| `insighthub_ingestion_queue_depth` | Queue dồn = worker không kịp xử lý |
| `insighthub_ingestion_errors_total` | Lỗi ingest |
| `insighthub_llm_tokens_total` | Phục vụ FinOps Day 6 |

### 3.3. RED / USE method

- **RED** (cho service): Rate, Errors, Duration.
- **USE** (cho resource): Utilization, Saturation, Errors.

---

## Segment 4 — Live Demo + Lab (60 phút)

### Bước 1 — Scrape InsightHub bằng Prometheus (15 phút)

InsightHub đã có `/metrics`. Cần cấu hình Prometheus scrape nó.

Prompt cho Claude Code:

```
Tạo ServiceMonitor (hoặc scrape config) trong observability/ để
kube-prometheus-stack scrape endpoint /metrics của service api
trong namespace insighthub. Verify Prometheus thấy target này.
```

Verify: trong Prometheus UI, target `insighthub-api` ở trạng thái `UP`.

### Bước 2 — Dashboard Grafana (15 phút)

Prompt:

```
Tạo Grafana dashboard JSON cho InsightHub trong observability/.
Panels theo RED method:
- RAG query rate (req/s)
- RAG error rate (%)
- RAG query latency p50/p95/p99
- LLM call latency p95
- Ingestion queue depth
- Documents theo status (pending/ready/failed)
```

Import dashboard vào Grafana, verify panels có dữ liệu.

### Bước 3 — Anomaly detection (15 phút)

**Lựa chọn A — PromQL-based (open-source, không cần Grafana Cloud Pro):**

Dùng framework `grafana/promql-anomaly-detection` — recording rules sinh "anomaly band" (upper/lower bound) từ mean + stddev, alert khi metric vượt band.

Prompt:

```
Dựa trên framework promql-anomaly-detection, tạo recording rules +
alerting rules cho metric insighthub_llm_call_latency_seconds.
Dùng strategy 'adaptive'. Alert khi latency vượt upper band.
```

**Lựa chọn B — Grafana Cloud ML:** dùng Forecasting + Outlier Detection trong Grafana Cloud (nếu có account Pro).

### Bước 4 — Inject incident + AI RCA (15 phút)

Trainer inject 1 lỗi vào InsightHub, ví dụ:
- LLM latency spike (mock chậm response)
- Ingestion queue dồn (dừng worker)
- Error burst (đổi DATABASE_URL sai)

Học viên dùng Claude Code (với Prometheus MCP từ Day 2):

```
InsightHub đang có bất thường. Query Prometheus, phân tích các metric
RED, xác định service nào bị ảnh hưởng và nguyên nhân gốc.
Viết RCA report ngắn: triệu chứng, metric chứng minh, nguyên nhân, đề xuất fix.
```

Quan sát Claude correlate metrics → ra RCA.

---

## Segment 5 — Workshop (10 phút)

Học viên dùng Prometheus MCP viết 1 PromQL phức tạp bằng natural language, so sánh tốc độ với viết tay.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | Prometheus scrape InsightHub | Target `UP` trong Prometheus |
| 2 | Grafana dashboard | Dashboard có panels RED, có dữ liệu |
| 3 | Anomaly alert config | Recording + alerting rules cho ≥ 1 metric |
| 4 | AI RCA report | 1 report cho incident inject — có metric chứng minh |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| Prometheus target `DOWN` | ServiceMonitor selector sai | Kiểm tra label khớp service |
| Dashboard panel "No data" | PromQL query sai metric name | Đối chiếu tên metric trong `/metrics` |
| Anomaly rule không trigger | Chưa đủ baseline data | Cần 24h+ data; với lab có thể giảm window |
| Prometheus MCP không query được | Endpoint Prometheus chưa expose | Port-forward hoặc cấu hình URL đúng |
| Queue depth metric = 0 | Worker chưa expose metric đó | Kiểm tra worker đã thêm Gauge (Day 1) |

---

## Homework (chuẩn bị Day 5)

1. Hoàn thiện dashboard + anomaly rules.
2. Tạo Slack workspace cá nhân.
3. Cài ngrok.
4. Xem skeleton `chatops-bot/` trong repo.

---

## Ghi chú cho Trainer

- PromQL-based anomaly (lựa chọn A) là khuyến nghị cho lab — open-source, không tốn tiền, học viên hiểu sâu cơ chế. Grafana Cloud ML (B) đẹp hơn nhưng cần Pro.
- Baseline data: trong môi trường lab khó có 7 ngày. Giải pháp — chạy 1 script sinh tải giả lập từ tối hôm trước, hoặc giảm window xuống vài giờ và giải thích rõ trade-off.
- Inject incident: chuẩn bị sẵn 2-3 kịch bản, mỗi học viên/nhóm 1 kịch bản khác nhau để tránh chép RCA của nhau.
- "Model as a service" chỉ 5 phút — nếu học viên hỏi sâu MLOps, chỉ sang slide roadmap riêng, không sa đà.
