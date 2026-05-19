// InsightHub Web — proxy route cho upload + chat
// Client component gọi /api/proxy/... → route này forward sang API service.
import { API_URL } from "@/lib/api";

export async function POST(req: Request) {
  const url = new URL(req.url);
  const target = url.searchParams.get("target");

  if (target === "upload") {
    const formData = await req.formData();
    const res = await fetch(`${API_URL}/documents`, {
      method: "POST",
      body: formData,
    });
    const data = await res.json();
    return Response.json(data, { status: res.status });
  }

  if (target === "chat") {
    const body = await req.json();
    const res = await fetch(`${API_URL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    return Response.json(data, { status: res.status });
  }

  return Response.json({ error: "unknown target" }, { status: 400 });
}
