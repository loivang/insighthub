-- InsightHub — Database schema khởi tạo
-- Chạy tự động khi Postgres container khởi tạo lần đầu.
--
-- LƯU Ý DEVOPS (Day 3):
-- Ở v0 schema được load qua docker-entrypoint-initdb.d.
-- Khi deploy lên K8s/RDS, học viên cần chuyển sang migration tool
-- (vd: Alembic, hoặc init job) — đây là điểm thảo luận Day 3.

CREATE EXTENSION IF NOT EXISTS vector;

-- ⚠️ BẢO MẬT: pgvector phải >= 0.8.2 (CVE-2026-3172, CVSS 8.1 —
-- buffer overflow khi parallel HNSW index build). Image dùng pgvector
-- 0.8.2+. Kiểm tra: SELECT extversion FROM pg_extension WHERE extname='vector';

-- ============ documents ============
CREATE TABLE IF NOT EXISTS documents (
    id          BIGSERIAL PRIMARY KEY,
    filename    TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'ready', 'failed')),
    chunk_count INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============ chunks ============
-- Vector dim = 1024 (voyage-3.5). Nếu đổi sang OpenAI text-embedding-3-small
-- thì phải đổi thành 1536 VÀ rebuild index — đây là lỗi thường gặp.
CREATE TABLE IF NOT EXISTS chunks (
    id          BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_text  TEXT NOT NULL,
    embedding   VECTOR(1024),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- HNSW index — chuẩn 2026 cho production RAG.
-- Có thể build TRƯỚC khi có data (khác IVFFlat) — tốt cho CI/CD.
-- m=16, ef_construction=64 là sweet spot cho embedding 768-1536 chiều.
CREATE INDEX IF NOT EXISTS chunks_embedding_hnsw_idx
    ON chunks USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS chunks_document_id_idx ON chunks(document_id);
CREATE INDEX IF NOT EXISTS documents_status_idx ON documents(status);
