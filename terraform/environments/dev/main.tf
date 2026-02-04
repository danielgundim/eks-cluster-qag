locals {
  environment = "dev"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = "platform"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = local.environment
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = true

  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = local.environment
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  public_access_cidrs            = var.public_access_cidrs

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  tags = local.common_tags
}

# ====================================================
# AWS Batch + EKS Integration
# ====================================================

module "batch_eks" {
  source = "../../modules/batch-eks"

  cluster_name          = module.eks.cluster_name
  eks_cluster_arn       = module.eks.cluster_arn
  oidc_provider_arn     = module.eks.oidc_provider_arn
  batch_namespace       = "aws-batch"
  batch_service_account = "aws-batch-sa"

  # Configurações do Compute Environment
  private_subnet_ids = module.vpc.private_subnets
  security_group_ids = [module.eks.node_security_group_id]
  max_vcpus          = 8

  tags = local.common_tags
}
