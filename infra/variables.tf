variable "aws_region" {
  description = "AWS region for InsightHub resources"
  type        = string
  default     = "us-east-1"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file for the Kubernetes provider"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Kubernetes namespace for InsightHub"
  type        = string
  default     = "insighthub-loivang"
}

variable "postgres_username" {
  description = "Postgres username for InsightHub"
  type        = string
  default     = "insighthub"
}

variable "postgres_password" {
  description = "Postgres password for InsightHub"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}
