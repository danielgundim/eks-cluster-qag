module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = "${var.project_name}-${var.environment}"
  kubernetes_version = var.cluster_version

  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.public_access_cidrs
  endpoint_private_access      = true

  # Habilita permissões de admin para o usuário que está criando o cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    base = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      disk_size      = var.node_disk_size
      capacity_type  = var.node_capacity_type

      # Força uso do user data padrão do EKS para AL2023
      enable_bootstrap_user_data = false

      labels = {
        role        = "base"
        environment = var.environment
      }

      tags = var.tags
    }
  }

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
  }

  tags = var.tags
}
