"""
InsightHub ChatOps Bot — SKELETON (Day 5)

⚠️ Đây là KHUNG. Học viên hoàn thiện trong Day 5.
Bot nhận câu hỏi vận hành từ Slack, dùng MCP backend (k8s + prometheus)
query thông tin, để Claude tóm tắt và trả lời.

Các phần TODO được đánh dấu rõ. Học viên dùng Claude Code để hoàn thiện.
"""
import logging
import os

from fastapi import FastAPI, Request

logging.basicConfig(level="INFO")
logger = logging.getLogger("chatops-bot")

app = FastAPI(title="InsightHub ChatOps Bot")

SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET", "")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")


@app.get("/healthz")
async def health():
    return {"status": "ok"}


@app.post("/slack/events")
async def slack_events(request: Request):
    """
    Endpoint nhận Slack event.

    TODO Day 5:
    1. Verify Slack signature (dùng SLACK_SIGNING_SECRET) — bảo mật bắt buộc.
    2. Xử lý url_verification challenge khi setup Slack app.
    3. Với app_mention / message: trích câu hỏi của user.
    4. Gọi handle_question() để xử lý.
    5. Trả kết quả về Slack channel.
    """
    body = await request.json()

    # Slack URL verification (giữ lại — cần khi cấu hình Slack app)
    if body.get("type") == "url_verification":
        return {"challenge": body.get("challenge")}

    # TODO: verify signature, parse event, gọi handle_question
    logger.info("Nhận Slack event: %s", body.get("type"))
    return {"ok": True}


async def handle_question(question: str) -> str:
    """
    Xử lý 1 câu hỏi vận hành về InsightHub.

    TODO Day 5:
    1. Dùng MCP backend (k8s + prometheus) để query thông tin cần thiết.
       Gợi ý: gọi Claude API với MCP servers, hoặc dùng kubectl/promql trực tiếp.
    2. Để Claude tóm tắt kết quả thành câu trả lời ngắn gọn.
    3. GHI AUDIT LOG mọi tool call (xem audit.py) — bắt buộc.
    4. Với hành động destructive: yêu cầu approval (human-in-the-loop).

    Câu hỏi mẫu cần trả lời được:
      - "InsightHub có healthy không?"
      - "Hôm nay ingest bao nhiêu tài liệu?"
      - "Pod nào đang lỗi?"
    """
    raise NotImplementedError("Học viên hoàn thiện trong Day 5")
