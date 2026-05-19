# Pre-Reading — Day 4: AIOps — Observability & Anomaly Detection

> **Module 7 — AI-Native DevOps** · Pillar B: Operate with AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 40-50 phút.
> Mục tiêu: hiểu lý thuyết AIOps và anomaly detection để triển khai đúng trên InsightHub.

---

## Mục lục

1. [Bối cảnh: từ monitoring đến AIOps](#1-bối-cảnh)
2. [Concept: AIOps là gì](#2-concept)
3. [Ba thế hệ AIOps](#3-ba-thế-hệ)
4. [Core Components: Observability stack & AIOps layer](#4-core-components)
5. [Anomaly Detection — thuật toán](#5-anomaly-detection)
6. [AI-Powered Root Cause Analysis](#6-rca)
7. [Features & công cụ 2026](#7-features)
8. [Implementation: instrument & detect](#8-implementation)
9. [Best Practices](#9-best-practices)
10. [Case Study](#10-case-study)
11. [Thuật ngữ & Đọc thêm](#11-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. Monitoring → Observability → AIOps

| Tầng | Trả lời câu hỏi |
|---|---|
| **Monitoring** | "Hệ thống có đang chạy không?" — dashboard, alert threshold |
| **Observability** | "Vì sao hệ thống hành xử thế này?" — metrics + logs + traces |
| **AIOps** | "Vấn đề là gì, ở đâu, sửa thế nào?" — AI tự correlate, RCA, đề xuất fix |

Observability cung cấp *instrumentation và telemetry*. AIOps đặt **lớp trí tuệ AI lên trên**: ML phát hiện anomaly, correlate event, tự động RCA.

### 1.2. Vì sao threshold tĩnh không đủ

Hệ thống thật có **seasonality**: error tăng sáng thứ Hai là bình thường, traffic giảm ban đêm là bình thường. Threshold cố định ("CPU > 80% → alert") tạo ra **báo động giả** hàng loạt → alert fatigue → kỹ sư bỏ qua cả alert thật.

### 1.3. Một con số

Đánh giá AIOps trên 400-service production (Q1 2026): alert reduction **70-95%** trong môi trường nhiều noise. Automated root-cause "hữu ích nhưng đừng tin mù lời gợi ý đầu tiên". Agentic LLM triage đã từ "demo-ware" thành thứ *đo được* — rút ngắn MTTR của Sev-2.

---

## 2. Concept

### 2.1. Định nghĩa AIOps

> **AIOps (AI for IT Operations)** dùng machine learning, NLP, và causal AI để tự động hóa các workflow observability — anomaly detection, root-cause analysis, alert correlation, incident remediation.

### 2.2. AIOps vs AI Observability — đừng nhầm

| | Định nghĩa |
|---|---|
| **AIOps (AI-Powered Observability)** | Dùng AI để monitor hạ tầng/ứng dụng truyền thống (server, DB, API) |
| **LLM Observability** | Monitor chính các hệ thống AI (LLM, agent, embedding) |

InsightHub đặc biệt — nó cần **cả hai**: AIOps để monitor 5 service, và LLM Observability để theo dõi LLM/embedding call. Day 4 tập trung AIOps; phần cost LLM đụng tới LLM observability sẽ học Day 6.

### 2.3. MTTR — chỉ số bắc cầu

**MTTR (Mean Time To Resolution)** — thời gian trung bình từ lúc sự cố xảy ra đến lúc khắc phục. Mục tiêu của AIOps cuối cùng là **giảm MTTR**. Mọi tính năng (anomaly detection, RCA, correlation) đều phục vụ mục tiêu này.

---

## 3. Ba thế hệ AIOps

| Thế hệ | Năm | Cách hoạt động | Sản phẩm "ship" gì |
|---|---|---|---|
| **Gen 1 — Rule-based** | ~2017 (định nghĩa Gartner gốc) | "Big data + ML cho IT ops". Threshold, rule. | Chủ yếu **noise reduction** |
| **Gen 2 — ML predictive** | ~2020-2024 | Học baseline, dự báo, phát hiện anomaly bằng ML | Anomaly detection, forecasting |
| **Gen 3 — Agentic AIOps** | 2025-2026 | LLM agent đọc alert storm, correlate, viết RCA, đề xuất runbook, đôi khi tự sửa | **Incident drafts** — đôi khi tự heal trước khi người để ý |

### 3.1. Gen 3 trông như thế nào

Phiên bản 2026 "ship incident drafts": một model GPT-class đọc cơn bão alert, correlate với deploy gần đây + topology, viết một đoạn root-cause khả dĩ, gợi ý bước runbook, mở một Slack thread đã tag sẵn on-call.

### 3.2. Cảnh báo về Gen 3

Nghiên cứu (FORGE '26, ICSE) chỉ ra LLM trong RCA vẫn có lỗi reasoning: "stalled, biased, confused". Bài học thực dụng: **automated root-cause hữu ích nhưng không tin mù lời gợi ý đầu tiên**. Agent vẫn cần human verify.

---

## 4. Core Components

### 4.1. Observability stack (nền)

| Trụ cột | Là gì | Công cụ phổ biến |
|---|---|---|
| **Metrics** | Số đo theo thời gian (latency, rate, CPU) | Prometheus, Mimir |
| **Logs** | Bản ghi sự kiện dạng text | Loki, OpenSearch |
| **Traces** | Đường đi request qua các service | Tempo, Jaeger |

Bộ ba này gọi là "three pillars of observability". Stack mở phổ biến: **LGTM** (Loki + Grafana + Tempo + Mimir).

### 4.2. AIOps layer (lớp trí tuệ ở trên)

| Thành phần | Vai trò |
|---|---|
| **Anomaly detection** | Phát hiện điểm bất thường trong metric/log/trace |
| **Correlation engine** | Gom nhiều anomaly liên quan thành 1 incident |
| **RCA engine** | Suy luận nguyên nhân gốc — ngày càng dùng LLM |
| **Knowledge graph** | Liên kết tín hiệu (service, deploy, topology) cho RCA giàu ngữ cảnh |
| **Remediation** | Đề xuất / thực thi runbook |

### 4.3. RED & USE — hai phương pháp instrument

| Method | Cho | Đo gì |
|---|---|---|
| **RED** | Service | **R**ate (req/s), **E**rrors (%), **D**uration (latency) |
| **USE** | Resource | **U**tilization, **S**aturation, **E**rrors |

Instrument InsightHub theo RED là cách bắt đầu chuẩn.

---

## 5. Anomaly Detection — thuật toán

### 5.1. Bốn nhóm thuật toán

| Nhóm | Thuật toán | Nguyên lý | Phù hợp |
|---|---|---|---|
| **Statistical** | z-score, IQR, MAD | Lệch bao nhiêu lần độ lệch chuẩn / MAD so với trung bình | Metric phân phối chuẩn, cần nhanh, đơn giản |
| **Time-series** | Prophet, ARIMA | Học pattern theo thời gian, dự báo, alert khi lệch dự báo | Metric có seasonality rõ (daily/weekly) |
| **Tree-based** | Isolation Forest, Random Cut Forest | Cô lập điểm bất thường bằng cây phân hoạch | Streaming, high-cardinality |
| **Deep learning** | LSTM, autoencoder | Học pattern phức tạp từ chuỗi dài | Pattern phức tạp, có nhiều training data |

### 5.2. Quy tắc chọn

> Bắt đầu **statistical** (đơn giản, đủ tốt cho phần lớn trường hợp). Chỉ lên ML/DL khi statistical không đủ. Đừng dùng LSTM khi z-score đã giải quyết được.

### 5.3. Anomaly band — cách statistical hoạt động trong PromQL

Framework `grafana/promql-anomaly-detection` minh họa rõ:
- **Recording rules** sinh "anomaly band" — upper/lower bound — từ mean + stddev.
- **Alerting rules** trigger khi metric vượt band.
- Hai strategy:
  - **adaptive** (mặc định): mean + stddev, smoothing 26h, high-pass filter. Tốt cho phát hiện thay đổi ngắn hạn, ít báo động giả với event lặp lại. Hợp metric phân phối chuẩn.
  - **robust**: median + MAD. Chịu được outlier. Hợp metric spiky / không phân phối chuẩn.
- Band gồm: short-term (biến động 24-26h), long-term (seasonality), margin (độ rộng tối thiểu khi biến động quá thấp).

### 5.4. Correlation > Detection

Phát hiện anomaly chỉ là bước 1. Giá trị thật nằm ở **correlate** nhiều anomaly để ra root cause. Một thermal spike có thể chỉ là "heavy workload hợp lệ", không phải lỗi — cần ngữ cảnh để phân biệt. Knowledge graph và causal AI làm việc này.

### 5.5. Hướng nghiên cứu mới (đáng biết)

- **Argos** (2025) — agentic time-series anomaly detection, LLM tự sinh rule.
- **Topology-Aware Active LLM Agent** (IEEE Access 2026) — "Sentinel Sampling": monitor 100% node bằng metric nhẹ, chỉ nâng lên high-resolution telemetry khi *ngữ cảnh ngữ nghĩa* cho thấy cần. Giải "observability tax" — chi phí telemetry leo thang.

---

## 6. AI-Powered Root Cause Analysis

### 6.1. RCA truyền thống vs AI-driven

| | RCA thủ công | AI-driven RCA |
|---|---|---|
| Cách làm | Người lọc log, đọc metric, suy luận | AI scan toàn bộ stack, correlate, đề xuất nguyên nhân |
| Thời gian | Hàng giờ | Vài phút |
| Output | Tùy kinh nghiệm người | Report có cấu trúc + link metric chứng minh |

### 6.2. Pattern Multi-Agent cho RCA (hướng tiên tiến)

Nghiên cứu 2025-2026 cho thấy hướng **Multi-Agent System** cho AIOps: nhiều agent có vai trò khác nhau (detection agent, diagnosis agent, remediation agent) cộng tác — hình thành và kiểm chứng giả thuyết để truy nguyên nhân gốc. InsightHub ở Day 4 chỉ dùng single-agent RCA; multi-agent là hướng nâng cao.

### 6.3. Cẩn trọng — hallucination trong RCA

LLM dễ hallucinate khi data mơ hồ — "over-correlate", gán thermal spike cho process nền vô hại. Nghiên cứu chỉ ra: **prompt engineering là một dạng guardrail** cho AIOps. Agent "skeptical" (được prompt hoài nghi) giảm false positive đáng kể. Bài học: prompt RCA tốt = yêu cầu agent dẫn *bằng chứng metric*, không kết luận vội.

---

## 7. Features & công cụ 2026

### 7.1. Landscape công cụ AIOps

| Công cụ | Loại | Ghi chú |
|---|---|---|
| **Grafana Sift / SRE agent** | AI diagnostic trong Grafana Cloud | Tự correlate metrics/logs/traces, knowledge graph cho RCA |
| **Grafana ML** (Forecasting + Outlier) | Anomaly detection trong Grafana Cloud | Học historical data, dynamic alerting |
| **grafana/promql-anomaly-detection** | Framework open-source | PromQL recording rules — không cần Cloud Pro |
| **Datadog Watchdog / Bits AI** | AIOps thương mại | Alert reduction, agentic triage |
| **Dynatrace Davis** | AIOps thương mại | Causal AI |
| **OpenObserve** | Open-source observability + AI | Rẻ hơn Datadog 60-98% |

### 7.2. "Adaptive Telemetry" — kiểm soát observability tax

Grafana giới thiệu Adaptive Telemetry — lọc bỏ data không dùng, giảm 35-50% cost metrics/logs/traces. Liên quan tới ý "observability tax" — telemetry full-fidelity rất đắt, cần thông minh trong việc thu thập gì.

### 7.3. Khuyến nghị cho lab InsightHub

Dùng **PromQL-based anomaly** (`grafana/promql-anomaly-detection`) — open-source, không tốn tiền, học viên hiểu sâu cơ chế band. Grafana Cloud ML đẹp hơn nhưng cần account Pro.

---

## 8. Implementation — instrument & detect

### 8.1. InsightHub đã expose sẵn metric gì

File `api/app/core/metrics.py` (Prometheus client) định nghĩa:

| Metric | Loại | Vì sao chọn |
|---|---|---|
| `insighthub_rag_query_latency_seconds` | Histogram | Trải nghiệm người dùng (D trong RED) |
| `insighthub_llm_call_latency_seconds` | Histogram | Tách riêng — dễ inject spike để học anomaly |
| `insighthub_http_requests_total` | Counter | Rate + Errors (R, E trong RED) |
| `insighthub_ingestion_queue_depth` | Gauge | Queue dồn = worker không kịp — dễ inject backlog |
| `insighthub_ingestion_errors_total` | Counter | Lỗi ingest |
| `insighthub_llm_tokens_total` | Counter | Phục vụ FinOps Day 6 |

### 8.2. Loại metric Prometheus — ôn nhanh

- **Counter** — chỉ tăng (số request, số lỗi). Dùng `rate()` để ra tốc độ.
- **Gauge** — lên xuống (queue depth, nhiệt độ).
- **Histogram** — phân phối (latency) — cho phép tính p50/p95/p99 bằng `histogram_quantile()`.

### 8.3. Quy trình Day 4

```
1. Prometheus scrape InsightHub /metrics  (ServiceMonitor)
2. Grafana dashboard theo RED method      (rate, error, latency p50/p95/p99)
3. Anomaly detection                       (recording + alerting rules)
4. Inject incident → AI RCA                (Claude + Prometheus MCP)
```

---

## 9. Best Practices

### 9.1. Tránh anomaly noise

- Cần baseline **3-7 ngày** data trước khi bật alert thật.
- False positive = **cơ hội tinh chỉnh** model, không phải lý do tắt alert.
- Document các "anomaly mong đợi" (traffic tăng giờ hành chính, batch job đêm).
- Retraining theo lịch khi pattern hệ thống đổi (sau release lớn).

### 9.2. Correlation trước, alert sau

Đừng alert trên từng metric rời rạc → bão alert. Correlate trước, alert trên *incident* đã gom.

### 9.3. RCA — prompt để giảm hallucination

- Yêu cầu agent dẫn **bằng chứng metric cụ thể** cho mỗi kết luận.
- Yêu cầu agent nêu cả giả thuyết *bị loại* và lý do.
- Đừng tin lời gợi ý đầu tiên — verify.

### 9.4. "Model as a service" — góc nhìn DevOps về MLOps

DevOps engineer KHÔNG train model. Nhưng phải coi model như một service: có version, latency, cost, cần monitor, cần rollback. Đó là toàn bộ "MLOps" mà DevOps cần ở mức này. Train/tune model là việc của ML engineer.

### 9.5. Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Threshold tĩnh cho hệ có seasonality | Bão báo động giả |
| Bật anomaly alert khi chưa có baseline | Noise vô nghĩa |
| Tin RCA đầu tiên của LLM mù quáng | Sửa nhầm nguyên nhân |
| Alert trên metric rời rạc | Alert fatigue |
| Thu thập 100% telemetry full-fidelity mọi lúc | Observability tax — chi phí leo thang |

---

## 10. Case Study

### 10.1. Observability cho InsightHub — bài Day 4

InsightHub có 2 metric "đẹp" để dạy anomaly:
- **LLM call latency** — dễ inject spike (mock LLM chậm). Phân phối thường lệch → hợp strategy *robust* hoặc *adaptive*.
- **Ingestion queue depth** — dừng worker → queue dồn ngay. Gauge tăng vọt → anomaly rõ ràng.

Học viên: instrument 5 service → dashboard RED → anomaly band cho LLM latency → trainer inject incident → Claude + Prometheus MCP làm RCA.

### 10.2. Vì sao kiến trúc async (Day 1) quan trọng ở đây

Ở Day 1 ta tách `ingestion-worker` + Redis queue. Chính nhờ đó Day 4 mới có **queue depth** để observe. Nếu ingestion vẫn đồng bộ trong API, sẽ không có queue, không có metric backlog — bài AIOps mất một nửa giá trị. Đây là minh họa **system thinking**: quyết định kiến trúc ở Day 1 mở ra khả năng quan sát ở Day 4.

### 10.3. Bài học từ ngành — "never trust the first suggestion"

Đánh giá 400-service thực tế kết luận: agentic triage rút ngắn MTTR thật, nhưng automated root-cause "không bao giờ tin lời gợi ý đầu tiên một cách mù quáng". Day 4 dạy đúng tinh thần đó — AI làm RCA nhanh, con người verify bằng metric.

---

## 11. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **AIOps** — AI for IT Operations.
- **Observability** — khả năng hiểu trạng thái hệ thống qua metrics/logs/traces.
- **MTTR** — Mean Time To Resolution.
- **RED / USE** — phương pháp instrument (service / resource).
- **Anomaly band** — dải upper/lower bound; vượt band = anomaly.
- **Seasonality** — pattern lặp theo thời gian (daily/weekly).
- **RCA** — Root Cause Analysis.
- **Correlation** — gom nhiều anomaly liên quan thành 1 incident.
- **LGTM** — Loki + Grafana + Tempo + Mimir.
- **Observability tax** — chi phí telemetry leo thang ở hyperscale.

### Đọc thêm (khuyến nghị trước buổi)

- `grafana/promql-anomaly-detection` — README framework.
- Grafana — "Get started with metric forecasting and anomaly detection".

### Tự kiểm tra trước khi đến lớp

1. Monitoring, Observability, AIOps khác nhau thế nào?
2. Vì sao threshold tĩnh gây alert fatigue?
3. Ba thế hệ AIOps — Gen 3 "ship" gì khác Gen 1?
4. 4 nhóm thuật toán anomaly detection — khi nào dùng statistical, khi nào ML?
5. "Correlation > Detection" nghĩa là gì?
6. Vì sao không nên tin RCA đầu tiên của LLM?
7. Kiến trúc async ở Day 1 liên quan gì tới bài AIOps Day 4?

---

*Pre-reading Day 4 — Module 7 AI-Native DevOps.*
