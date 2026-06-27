variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Deployment environment (prod | staging)"
  type        = string
  default     = "prod"
}

variable "vpc_id" {
  description = "VPC ID for all resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS and ElastiCache"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_password" {
  description = "RDS master password — supply via TF_VAR_db_password env var, never hardcode"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "app_image" {
  description = "ECR image URI for the Next.js app (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/lumigift:latest)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name managed in Route 53 (e.g. lumigift.app)"
  type        = string
}

variable "vpn_cidr_blocks" {
  description = "CIDR blocks for VPN/bastion SSH access (e.g. [\"10.0.0.0/8\"])"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR ranges of private subnets — used to restrict bastion egress"
  type        = list(string)
}
