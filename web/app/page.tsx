import UploadPanel from "@/components/UploadPanel";
import ChatPanel from "@/components/ChatPanel";
import { listDocuments } from "@/lib/api";
import type { Document } from "@/lib/api";

export const dynamic = "force-dynamic";

export default async function Home() {
  let docs: Document[] = [];
  try {
    docs = await listDocuments();
  } catch {
    docs = [];
  }

  return (
    <div className="container">
      <header>
        <h1>InsightHub</h1>
        <p>RAG Notebook — running project cho module AI-Native DevOps</p>
      </header>

      <div className="grid">
        <UploadPanel initial={docs} />
        <ChatPanel />
      </div>

      <footer>
        InsightHub v0.1.0 · Stack: Next.js 15 + FastAPI + pgvector + Redis ·
        Đây là project nền cho 7 ngày training — học viên sẽ containerize,
        deploy, observe, secure và tối ưu cost.
      </footer>
    </div>
  );
}
