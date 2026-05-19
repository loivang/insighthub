# Tài liệu đọc trước — Module 7: AI-Native DevOps

Tài liệu lý thuyết học viên **đọc trước mỗi buổi học**. Khác với lab guide
(hướng dẫn thực hành tại lớp) — tài liệu này cung cấp nền tảng khái niệm.

## Cách dùng

- Đọc tài liệu của Day N **trước khi** tới buổi học Day N.
- Mỗi topic ~16-28 phút đọc. Mỗi ngày 2 topic.
- Cuối mỗi topic có phần "Tự kiểm tra" — trả lời được nghĩa là đã sẵn sàng.
- Buổi học sẽ tập trung **thực hành**, không giảng lại lý thuyết cơ bản.

## Danh mục

| Day | Topic | File |
|---|---|---|
| 1 | AI-Native DevOps & Coding Agents Landscape | `day1/01-ai-native-devops-landscape.md` |
| 1 | Làm việc với AI Agent: Prompting, Context, Token | `day1/02-working-with-ai-agents.md` |
| 2 | MCP — Kiến trúc & Khái niệm cốt lõi | `day2/01-mcp-architecture.md` |
| 2 | Bảo mật MCP — Least-Privilege | `day2/02-mcp-security.md` |
| 3 | AI-Powered Infrastructure as Code | `day3/01-ai-powered-iac.md` |
| 3 | AI-Generated CI/CD Pipelines | `day3/02-ai-generated-cicd.md` |
| 4 | AIOps & Nền tảng Observability | `day4/01-aiops-observability.md` |
| 4 | AI-Powered Root Cause Analysis | `day4/02-ai-powered-rca.md` |
| 5 | ChatOps 2.0 — Vận hành qua đối thoại | `day5/01-chatops-2.0.md` |
| 5 | Human-in-the-Loop & Audit cho AI Agent | `day5/02-human-in-the-loop-audit.md` |
| 6 | LLM Security — OWASP LLM & Agentic AI Top 10 | `day6/01-llm-security-owasp.md` |
| 6 | FinOps cho LLM — Quản trị chi phí AI | `day6/02-finops-llm.md` |

> Day 7 (Showcase) không có tài liệu đọc trước — là buổi tổng kết & demo.

## Cấu trúc mỗi tài liệu

Mỗi tài liệu theo cùng một mạch, từ cơ bản tới nâng cao:

1. **Lý thuyết cơ bản** — nền tảng, vì sao chủ đề quan trọng
2. **Concept & Core Components** — khái niệm và thành phần cốt lõi
3. **Features** — tính năng, công cụ cụ thể
4. **Implementation** — cách triển khai, quy trình
5. **Best Practices** — thực hành tốt + anti-patterns
6. **Case Study** — tình huống thực tế minh họa bài học
7. **Tự kiểm tra** — câu hỏi ôn tập

## Mối liên hệ với tài liệu khác

- `docs/lab-guides/` — hướng dẫn thực hành tại lớp (5-segment, hands-on).
- `docs/reading/` — tài liệu này: lý thuyết đọc trước.
- Hai bộ tài liệu bổ trợ nhau: đọc lý thuyết trước → vào lớp thực hành.

## Lưu ý cho Trainer

- Tài liệu viết theo trạng thái công nghệ tháng 5/2026. Một số chi tiết (model
  name, giá token, tên công cụ) có thể thay đổi — rà lại trước mỗi kỳ học.
- Case study được viết để minh họa bài học, dựa trên tình huống điển hình trong
  ngành (một số dựa trên CVE/sự cố có thật như EchoLeak CVE-2025-32711).
- Phần "Tự kiểm tra" có thể dùng làm quiz đầu buổi để kiểm tra học viên đã đọc.
