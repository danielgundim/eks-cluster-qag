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

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_cluster_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  policy_arn    = var.github_actions_eks_access_policy_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

# ====================================================
# AWS Load Balancer Controller (EKS)
# ====================================================

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"

  name                                   = "${module.eks.cluster_name}-aws-load-balancer-controller"
  use_name_prefix                        = false
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.common_tags
}

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa_role.arn
    }
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    }
  ]

  depends_on = [
    module.aws_load_balancer_controller_irsa_role,
    kubernetes_service_account_v1.aws_load_balancer_controller
  ]
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
