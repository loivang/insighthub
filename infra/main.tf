terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "db" {
  name        = "${var.namespace}-db-sg"
  description = "Security group for InsightHub Postgres"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow Postgres traffic from within the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow outbound traffic to other VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  tags = {
    Name = "${var.namespace}-db-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.namespace}-redis-sg"
  description = "Security group for InsightHub Redis"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow Redis traffic from within the VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow outbound traffic to other VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  tags = {
    Name = "${var.namespace}-redis-sg"
  }
}

resource "aws_db_subnet_group" "insighthub" {
  name       = "${var.namespace}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.namespace}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "insighthub" {
  name        = "${var.namespace}-postgres-pg"
  family      = "postgres16"
  description = "Postgres parameter group for InsightHub"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "${var.namespace}-postgres-pg"
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.namespace}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_kms_key" "rds_performance_insights" {
  description              = "KMS key for RDS Performance Insights encryption"
  deletion_window_in_days  = 30
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow account administrators to manage the key"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow RDS to use the key for performance insights"
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_db_instance" "insighthub" {
  identifier                            = "${var.namespace}-db"
  engine                                = "postgres"
  engine_version                        = "16"
  instance_class                        = "db.t4g.micro"
  allocated_storage                     = 20
  storage_encrypted                     = true
  publicly_accessible                   = false
  db_subnet_group_name                  = aws_db_subnet_group.insighthub.name
  vpc_security_group_ids                = [aws_security_group.db.id]
  username                              = var.postgres_username
  password                              = var.postgres_password
  skip_final_snapshot                   = true
  backup_retention_period               = 7
  auto_minor_version_upgrade            = true
  parameter_group_name                  = aws_db_parameter_group.insighthub.name
  deletion_protection                   = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  iam_database_authentication_enabled   = true
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  multi_az                              = true
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds_performance_insights.arn
  performance_insights_retention_period = 7
  copy_tags_to_snapshot                 = true

  tags = {
    Name = "${var.namespace}-postgres"
  }
}

resource "aws_elasticache_subnet_group" "insighthub" {
  name       = "${var.namespace}-redis-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.namespace}-redis-subnet-group"
  }
}

resource "aws_elasticache_cluster" "insighthub" {
  #checkov:skip=CKV_AWS_31:Redis at-rest encryption is unavailable for aws_elasticache_cluster; lab sample uses a single cache node.
  #checkov:skip=CKV_AWS_191:Lab sample uses aws_elasticache_cluster, which does not support a customer-managed KMS key.
  cluster_id                 = "${var.namespace}-redis"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t4g.micro"
  num_cache_nodes            = 1
  subnet_group_name          = aws_elasticache_subnet_group.insighthub.name
  security_group_ids         = [aws_security_group.redis.id]
  port                       = 6379
  transit_encryption_enabled = true
  snapshot_retention_limit   = 7

  tags = {
    Name = "${var.namespace}-redis"
  }
}

resource "kubernetes_namespace" "insighthub" {
  metadata {
    name = var.namespace
    labels = {
      app = "insighthub"
    }
  }
}
