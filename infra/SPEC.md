# Day 3 SPEC - Minimal Lab

## Goal

Create the minimum Day 3 IaC and pipeline artifacts needed for the lab.

## Acceptance

- Terraform files exist in `infra/`.
- GitHub Actions workflow exists in `.github/workflows/iac.yml`.
- Workflow has `fmt`, `lint`, `scan`, and `plan` jobs.
- Terraform creates RDS PostgreSQL, Redis, and a Kubernetes namespace.
- The namespace defaults to `insighthub-loivang` on the shared `do2509`
  cluster.
- `terraform fmt`, `terraform validate`, `tflint`, and `checkov` can run.

## Constraints

- Keep the Terraform shape close to the lab sample.
- Avoid production-only files such as Helm charts, custom Rego, or separate
  backend/provider files unless the lab asks for them.
- Do not commit real secrets.
