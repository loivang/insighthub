# AGENTS.md - InsightHub

Repository instructions for Codex and other coding agents. Read this before
changing code or infrastructure.

## Project

InsightHub is a RAG Notebook training project for the AI-Native DevOps module.
Users upload `.txt`, `.md`, or `.pdf` documents and ask questions grounded in
those documents.

Do not redesign the app from scratch. The running-project goal is to
DevOps-enable the existing app across 7 days: containerize, deploy, observe,
secure, and optimize cost.

## Architecture

Current local stack:

```text
web -> api -> redis -> ingestion-worker -> postgres + pgvector
        |                                      ^
        +------------- retrieval + LLM --------+
```

- `web`: Next.js 15 App Router. Calls API via `API_INTERNAL_URL`.
- `api`: FastAPI + async psycopg3. Handles upload, status, retrieval, chat.
- `ingestion-worker`: Python + ARQ. Reuses `api/app/services/ingestion.py`.
- `redis`: Redis 7 queue/job state.
- `postgres`: PostgreSQL 16 + pgvector 0.8.2. Schema: `infra/db/init.sql`.

## API Contract

Preserve this unless the user explicitly asks for a breaking change.

- `POST /documents`: multipart upload, returns `202` with
  `{ "document_id": int, "status": "queued" }`. It must enqueue and return,
  not block on chunking/embedding/storage.
- `GET /documents/{id}`: returns public status
  `queued | processing | ready | failed`.
- `POST /chat`: returns `200` with an answer for ready documents.

Note: public `queued` can map to internal DB status `pending`. The frontend
polls the status field, so do not casually change status semantics.

## Hard Constraints

- Never hardcode secrets. Use env vars, GitHub Actions secrets, AWS Secrets
  Manager, or Kubernetes Secrets.
- `EMBEDDING_DIM` must match `VECTOR(n)` in `infra/db/init.sql`.
- Keep pgvector at `0.8.2` or newer.
- `process_document()` must be idempotent; worker retries must not duplicate
  chunks for the same document.
- Non-retriable ingestion failures should set status `failed`, not retry forever.
- Do not copy ingestion logic into `ingestion-worker`; share through
  `api/app/services/ingestion.py`.
- There is no migration framework. Schema edits may require
  `docker compose down -v` in dev, which deletes local data.

## Common Commands

```bash
# Full local stack
docker compose up --build

# Dependencies only
docker compose up -d postgres redis

# API iteration
docker compose up --build api

# Logs
docker compose logs -f api
docker compose logs -f ingestion-worker

# Queue length
docker compose exec redis redis-cli LLEN arq:queue:ingestion

# Smoke test
bash scripts/smoke-test.sh

# Daily verification
bash scripts/verify-day-1-local.sh
bash scripts/verify-day-2-local.sh
bash scripts/verify-day-3-local.sh
```

Destructive reset, only with explicit user approval:

```bash
docker compose down -v
docker compose up --build
```

Web commands from `web/`:

```bash
npm install
npm run build
npm run lint
```

## Day 3: IaC And Pipeline

Day 3 creates Terraform and CI/CD artifacts while preserving local app behavior.

Expected Terraform files under `infra/`:

- `providers.tf`
- `backend.tf`
- `main.tf`
- `variables.tf`
- `outputs.tf`

Expected infrastructure:

- EKS namespace `insighthub-<env>`.
- RDS PostgreSQL 16 with pgvector support, encrypted, not public.
- ElastiCache Redis 7 in private networking.
- IRSA: Kubernetes ServiceAccount annotated with IAM role.
- Required tags: `project`, `environment`, `owner`, `cost_center`,
  `managed_by`.
- S3 remote state with DynamoDB locking.

Expected workflow: `.github/workflows/iac.yml` with fmt, validate/lint, checkov,
policy checks, plan, Infracost, and manual approval before apply. AWS auth must
use GitHub OIDC, not long-lived AWS keys.

Day 3 verification commands:

```bash
cd infra
terraform fmt -check -recursive
terraform init -backend=true
terraform validate
tflint --recursive
checkov -d .
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test --policy policies tfplan.json
infracost breakdown --path .
```

Repository check:

```bash
bash scripts/verify-day-3-local.sh
```

Deployment smoke checks:

```bash
kubectl get ns insighthub-dev
kubectl get pods -n insighthub-dev
curl https://insighthub-dev.example.com/health
```

Also verify upload returns `202`, document status becomes `ready`, and chat
returns `200`.

## Working Style

- Read existing files before editing.
- Keep edits scoped to the requested task/day.
- Prefer existing conventions over new abstractions.
- Plan first for Day 3 work; then implement in small verifiable increments.
- Do not apply Terraform if the plan has unexpected destroys.
- Do not commit `.env`, kubeconfig, Terraform state, provider caches, or secrets.
- Keep AI prompt logs in `ai-prompts/dayN.md` when required for submission.

## Day 3 Evidence

Preserve evidence for submission:

- Terraform module diff/URL.
- Green GitHub Actions run.
- Checkov evidence with no HIGH/CRITICAL findings.
- Infracost evidence.
- Live HTTPS URL.
- Smoke test evidence for `/health`, upload, status, and chat.
