# Lab Guides — Module 7: AI-Native DevOps

Hướng dẫn lab chi tiết cho 7 ngày training, theo running project **InsightHub**.

| Day | File | Pillar | Chủ đề |
|---|---|---|---|
| 1 | `Day1-AI-Coding-Agents.md` | A. Develop | AI Coding Agents & Refactor InsightHub |
| 2 | `Day2-MCP-Protocol.md` | A. Develop | MCP Protocol — USB-C cho AI Agents |
| 3 | `Day3-AI-IaC-Pipeline.md` | A. Develop | AI-Powered IaC & Pipeline Engineering |
| 4 | `Day4-AIOps-Observability.md` | B. Operate | AIOps — Observability & Anomaly Detection |
| 5 | `Day5-ChatOps-Incident-Response.md` | B. Operate | ChatOps 2.0 + AI Incident Response |
| 6 | `Day6-Security-Governance-FinOps.md` | C. Govern | LLM Security, Governance & FinOps |
| 7 | `Day7-Showcase.md` | Showcase | InsightHub Production Demo |

## Cấu trúc mỗi lab guide

- **Mục tiêu buổi học** + Daily Artifact cần nộp
- **Chuẩn bị trước buổi** (checklist)
- **5 segment**: Recap → Concept → Best Practice → Live Demo/Lab → Workshop
- **Daily Artifact checklist** — cách verify
- **Troubleshooting** — lỗi thường gặp + cách xử lý
- **Homework** — chuẩn bị buổi sau
- **Ghi chú cho Trainer** — lưu ý vận hành

## Nguyên tắc xuyên suốt

1. **Running project** — InsightHub tiến hóa mỗi ngày, không học rời rạc.
2. **Solo track** — mỗi học viên làm độc lập, app code là GIVEN.
3. **AI-augmented** — mọi task đều có AI agent tham gia; học viên lưu prompt log.
4. **Verify được** — mỗi ngày ra 1 artifact kiểm tra được, chấm async.

## Lưu ý cho Trainer trước khi dùng

- Một số công cụ thay đổi nhanh (MCP servers, Promptfoo plugins, Grafana). Mỗi
  lab guide có ghi chú "verify 1 ngày trước buổi học" ở phần dành cho trainer.
- Đáp án (reference solutions) cho Day 3-6 nên build dần theo tiến độ để luôn
  khớp công cụ hiện hành — xem `docs/reference-solutions/`.
- Skeleton code đã có sẵn trong repo cho Day 5 (`chatops-bot/`) và Day 6
  (`security/promptfooconfig.yaml`) — học viên hoàn thiện, không viết from scratch.
