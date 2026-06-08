# Day 3 AI Prompts

## Prompt 1 - Constraint-first Terraform plan

**Tool**: Codex
**Time**: 2026-06-08

**Prompt**:
Read the Day 3 project specification and audit the existing repo. Create an
implementation plan for Terraform and CI/CD that can pass Day 3 without editing
code yet. Use an existing EKS cluster, private RDS PostgreSQL 16 with pgvector,
private Redis, IRSA, checkov/tflint/Conftest gates, GitHub Actions OIDC, and
InsightHub live smoke tests.

**Why it worked**:
- It forced an audit before implementation.
- It made the existing EKS cluster a hard constraint.
- It captured pass/fail gates before writing Terraform.

**What I changed**:
- Accepted the plan.
- Asked Codex to implement the Day 3 artifacts.

## Prompt 2 - Terraform and policy implementation

**Tool**: Codex
**Time**: 2026-06-08

**Prompt**:
Implement the Day 3 Terraform module to pass the specification: namespace,
RDS, Redis, Secrets Manager, IRSA, GitHub Actions OIDC role, required tags,
S3/DynamoDB backend, tflint config, Rego policies, and README. Do not hardcode
secrets and do not create a new EKS cluster.

**Why it worked**:
- It scoped Terraform to existing lab infrastructure.
- It included security and governance checks up front.
- It kept secrets out of repository files.

**What I changed**:
- Reviewed generated resources for public exposure and secret handling.
- Kept RDS/Redis private and encrypted.

## Prompt 3 - Pipeline and deployment artifacts

**Tool**: Codex
**Time**: 2026-06-08

**Prompt**:
Create GitHub Actions workflows and Helm deployment artifacts for Day 3. The
pipeline must include fmt, lint, scan, plan, policy, cost estimate, manual
apply, image build matrix, Trivy scan, Helm deploy, and smoke test. Use OIDC
for AWS and avoid long-lived credentials.

**Why it worked**:
- It separated infrastructure validation from app image deployment.
- It made manual approval and OIDC explicit.
- It produced evidence needed for submission.

**What I changed**:
- Added a small `/health` alias and document status endpoints so smoke tests
  match the Day 3 acceptance criteria.
