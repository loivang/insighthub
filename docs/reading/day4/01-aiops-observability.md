# Day 4 — Tài liệu đọc trước · Topic 1
# AIOps & Nền tảng Observability

> **Thời gian đọc:** ~25 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Monitoring vs Observability

- **Monitoring:** theo dõi các chỉ số *đã biết trước* — CPU, RAM, request rate.
  Trả lời câu hỏi "hệ thống có khỏe không?".
- **Observability:** khả năng *hiểu trạng thái bên trong* hệ thống từ dữ liệu nó
  phát ra — trả lời cả những câu hỏi *chưa biết trước* ("vì sao request này chậm?").

Observability dựa trên **3 trụ cột (three pillars):**

| Trụ cột | Là gì | Trả lời |
|---|---|---|
| **Metrics** | Số đo theo thời gian (counter, gauge, histogram) | "Cái gì đang xảy ra?" |
| **Logs** | Bản ghi sự kiện rời rạc | "Chi tiết chuyện gì đã xảy ra?" |
| **Traces** | Hành trình một request qua các service | "Chậm/lỗi ở đâu trong chuỗi?" |

### 1.2. AIOps là gì

**AIOps** = áp dụng AI/ML vào IT Operations. Mục tiêu: chuyển vận hành từ
**phản ứng** (reactive — chờ sự cố rồi xử lý) sang **chủ động & dự đoán**
(proactive & predictive — phát hiện sớm, ngăn trước khi ảnh hưởng người dùng).

### 1.3. Vì sao threshold tĩnh không còn đủ

Cách cũ: đặt ngưỡng cố định ("CPU > 80% thì báo động"). Vấn đề:

- Hệ thống thật có **seasonality** — tải cao giờ hành chính, thấp ban đêm; lỗi
  tăng sáng thứ Hai là bình thường. Threshold tĩnh báo động giả liên tục.
- Đặt ngưỡng quá cao → bỏ sót sự cố thật. Quá thấp → alert fatigue (nhờn cảnh báo).

AIOps học **baseline động** — biết "bình thường" của metric này tại giờ này,
ngày này là bao nhiêu, rồi cảnh báo khi lệch baseline.

---

## 2. Concept & Core Components

### 2.1. Ba thế hệ AIOps

| Thế hệ | Cách hoạt động | Hạn chế |
|---|---|---|
| **Gen 1 — Rule-based** | Threshold tĩnh, rule cứng | Báo động giả với hệ có seasonality |
| **Gen 2 — ML anomaly detection** | Học baseline, cảnh báo khi lệch | Vẫn cần người phân tích & RCA |
| **Gen 3 — Agentic AIOps** | AI tự correlate, RCA, đề xuất fix, đôi khi tự sửa | Cần guardrails (Day 6) |

Năm 2026, industry đang ở Gen 2 → Gen 3. Các nền tảng (Grafana Sift, Datadog
Bits AI, Dynatrace Davis) đều đã có "agent" làm RCA.

### 2.2. Anomaly Detection — phát hiện bất thường

Anomaly = điểm dữ liệu lệch đáng kể khỏi baseline. Các nhóm thuật toán:

| Nhóm | Thuật toán | Phù hợp |
|---|---|---|
| **Statistical** | z-score, IQR, MAD (median absolute deviation) | Nhanh, đơn giản; z-score cho metric phân phối chuẩn, MAD cho metric nhiều spike |
| **Time-series** | Prophet, ARIMA | Metric có seasonality rõ (daily/weekly) |
| **Tree-based** | Isolation Forest, Random Cut Forest | Streaming, high-cardinality |
| **Deep learning** | LSTM | Pattern phức tạp, cần nhiều data |

**Quy tắc chọn:** bắt đầu từ statistical (đơn giản, đủ tốt cho hầu hết trường
hợp). Chỉ lên ML/DL khi statistical không đủ. Đừng dùng LSTM khi z-score giải
quyết được.

### 2.3. Anomaly band (dải bất thường)

Một cách triển khai phổ biến: từ dữ liệu lịch sử, tính **dải trên/dưới** (upper/
lower band) cho metric. Khi giá trị thật vượt ra ngoài dải → anomaly.

- **Short-term band:** giãn theo biến động trong ~24-26h gần đây.
- **Long-term band:** tính cả seasonality (pattern daily/weekly).
- **Margin band:** độ rộng tối thiểu, tránh báo động giả khi biến động quá thấp.

### 2.4. Correlation > Detection

Phát hiện một anomaly mới là bước 1. Giá trị thật nằm ở **correlate** nhiều
anomaly để ra **root cause**. Ví dụ: latency tăng + error rate tăng + DB
connection pool đầy → ba anomaly này cùng trỏ về một nguyên nhân. Nền tảng AIOps
hiện đại dùng **knowledge graph** để liên kết tín hiệu.

---

## 3. Features — đo cái gì cho đúng

### 3.1. RED method (cho service)

| Chữ | Metric | Ý nghĩa |
|---|---|---|
| **R**ate | request/giây | Lưu lượng |
| **E**rrors | tỉ lệ lỗi | Độ tin cậy |
| **D**uration | latency (p50/p95/p99) | Trải nghiệm người dùng |

### 3.2. USE method (cho resource)

| Chữ | Metric | Ý nghĩa |
|---|---|---|
| **U**tilization | % sử dụng | Tài nguyên đang dùng bao nhiêu |
| **S**aturation | mức độ quá tải / hàng đợi | Có đang nghẽn không |
| **E**rrors | số lỗi | Resource có lỗi không |

### 3.3. Percentile — vì sao p95/p99 quan trọng hơn trung bình

Latency trung bình che giấu trải nghiệm tệ. Nếu 95% request nhanh nhưng 5% rất
chậm, "trung bình" vẫn đẹp — nhưng 5% người dùng đó đang khổ. **p95/p99** (95%/
99% request nhanh hơn giá trị này) phản ánh trải nghiệm thật tốt hơn.

### 3.4. Loại metric

| Loại | Đặc điểm | Ví dụ |
|---|---|---|
| **Counter** | Chỉ tăng | tổng số request, tổng token |
| **Gauge** | Lên xuống tự do | queue depth, số pod đang chạy |
| **Histogram** | Phân phối giá trị | latency theo bucket |

---

## 4. Implementation — observability cho InsightHub

### 4.1. InsightHub đã phát ra gì

InsightHub đã được instrument sẵn (`api/app/core/metrics.py`), expose tại
endpoint `/metrics` theo định dạng Prometheus:

| Metric | Loại | Vì sao quan trọng |
|---|---|---|
| `insighthub_rag_query_latency_seconds` | Histogram | Trải nghiệm người dùng (RED-Duration) |
| `insighthub_llm_call_latency_seconds` | Histogram | Tách riêng LLM — dễ quan sát spike |
| `insighthub_ingestion_queue_depth` | Gauge | Queue dồn = worker không kịp (USE-Saturation) |
| `insighthub_ingestion_errors_total` | Counter | Lỗi ingest |
| `insighthub_llm_tokens_total` | Counter | Phục vụ FinOps (Day 6) |

### 4.2. Pipeline observability

```
InsightHub /metrics → Prometheus (scrape & lưu) → Grafana (dashboard)
                            │
                            └→ Anomaly rules → Alert
                            └→ Prometheus MCP → AI query & RCA
```

### 4.3. "Model as a service" — góc nhìn DevOps về MLOps

Một câu hỏi hay gặp: "DevOps có cần học MLOps không?"

Trả lời: DevOps engineer **không train model**. Đó là việc của ML engineer.
Nhưng DevOps cần coi **model là một service** — nó có version, có latency, có
cost, có thể lỗi, cần monitor và rollback. Toàn bộ "MLOps" mà một DevOps engineer
cần chính là: deploy model như một service, observe nó như observe service khác.
Phần Kubeflow/MLflow/train pipeline nằm ngoài phạm vi vai trò DevOps.

---

## 5. Best Practices

1. **Đo theo RED/USE** — có khung, không đo lung tung.
2. **Dùng p95/p99**, không chỉ trung bình.
3. **Bắt đầu từ statistical anomaly detection** — đơn giản trước, ML sau.
4. **Cần baseline 3-7 ngày** trước khi bật alert — thiếu data thì anomaly vô nghĩa.
5. **Correlation > detection** — mục tiêu là root cause, không phải đếm anomaly.
6. **False positive là cơ hội tinh chỉnh** — không phải thứ để bỏ qua.
7. **Document "anomaly mong đợi"** — vd traffic tăng giờ cao điểm.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Threshold tĩnh cho hệ có seasonality | Báo động giả triền miên → alert fatigue |
| Bật anomaly alert khi chưa đủ baseline | Cảnh báo nhiễu, mất niềm tin |
| Đo trung bình thay vì percentile | Che giấu trải nghiệm tệ của nhóm nhỏ |
| Dùng LSTM khi z-score là đủ | Phức tạp hóa không cần thiết |
| Phát hiện anomaly nhưng không correlate | Có cảnh báo, không có nguyên nhân |

---

## 6. Case Study — Alert fatigue và cái giá của threshold tĩnh

**Bối cảnh:** một team đặt alert "error rate > 1% → page on-call". Hợp lý trên
giấy.

Thực tế: mỗi sáng thứ Hai 9h, lượng người dùng tăng vọt, một số request lỗi
thoáng qua đẩy error rate lên 1.5% trong vài phút — rồi tự ổn định. Alert nổ.
On-call bị đánh thức. Kiểm tra: không có gì nghiêm trọng.

Lặp lại mỗi tuần. Sau một tháng, on-call bắt đầu **bỏ qua** alert error rate —
"chắc lại spike thứ Hai thôi". Rồi một thứ Hai, error rate lên 1.5% vì **lý do
thật** (một dependency hỏng). Không ai phản ứng — vì alert đó đã bị nhờn.

### Nếu dùng anomaly detection

Anomaly detection học baseline: biết rằng sáng thứ Hai 9h, error rate ~1.5% là
**bình thường** cho khung giờ đó. Nó không báo động cho spike thứ Hai thông
thường — nhưng nếu error rate lên 1.5% vào 3h sáng (khi baseline ~0.1%), nó báo
ngay, vì *đó* mới là bất thường thật.

**Bài học:** threshold tĩnh không phân biệt được "1.5% lúc 9h thứ Hai" (bình
thường) với "1.5% lúc 3h sáng" (bất thường). Alert fatigue không phải lỗi của
on-call — là lỗi của công cụ cảnh báo không hiểu ngữ cảnh. AIOps giải quyết
chính xác vấn đề này.

---

## Tự kiểm tra trước buổi học

1. Ba trụ cột của observability là gì? Mỗi cái trả lời câu hỏi gì?
2. Vì sao threshold tĩnh gây alert fatigue?
3. Khi nào dùng statistical, khi nào dùng ML cho anomaly detection?
4. RED và USE method đo gì?
5. Vì sao p95/p99 quan trọng hơn latency trung bình?

---

## Đọc thêm (tùy chọn)

- Grafana — anomaly detection & forecasting docs
- github.com/grafana/promql-anomaly-detection
