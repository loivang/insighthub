# InsightHub Day 3 Infrastructure

Minimal Terraform for the Day 3 lab artifact.

## Files

- `main.tf`: providers and AWS/Kubernetes resources
- `variables.tf`: lab inputs
- `outputs.tf`: resource outputs
- `db/init.sql`: pgvector schema used by InsightHub

## Resources

- Kubernetes namespace
- RDS PostgreSQL 16
- ElastiCache Redis 7
- Security groups scoped to the default VPC

## Lab Cluster

The shared Kubernetes cluster is `do2509`. Make sure your kubeconfig context
points to that cluster before running Terraform:

```bash
kubectl config current-context
```

The default namespace is `insighthub-loivang` to avoid conflicts with other
students on the shared cluster.

## Verify

```bash
cd infra
terraform fmt -check -recursive
terraform init
terraform validate
tflint --recursive
checkov -d . --framework terraform --soft-fail-on LOW,MEDIUM
terraform plan
```

Do not apply if the plan contains unexpected destroys.
