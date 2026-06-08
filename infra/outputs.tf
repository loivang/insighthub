output "aws_region" {
  description = "AWS region used for InsightHub resources"
  value       = var.aws_region
}

output "db_endpoint" {
  description = "Postgres endpoint for InsightHub"
  value       = aws_db_instance.insighthub.address
}

output "redis_endpoint" {
  description = "Redis endpoint for InsightHub"
  value       = aws_elasticache_cluster.insighthub.cache_nodes[0].address
}

output "namespace" {
  description = "Kubernetes namespace created for InsightHub"
  value       = kubernetes_namespace.insighthub.metadata[0].name
}
