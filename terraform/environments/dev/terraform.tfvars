project_name = "qag"
aws_profile  = "tii"
region       = "us-east-1"

cluster_version                = "1.35"
vpc_cidr                       = "10.0.0.0/16"
az_count                       = 3
public_access_cidrs            = ["0.0.0.0/0"]
cluster_endpoint_public_access = true

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3
batch_instance_profile_arn = "arn:aws:iam::767398116920:instance-profile/eks-52ce49b1-d4ee-60bf-e956-a8a02e872494"

eks_managed_node_groups = {
  base = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    disk_size      = 20
    capacity_type  = "ON_DEMAND"

    enable_bootstrap_user_data = false

    labels = {
      role        = "base"
      environment = "dev"
      workload    = "cpu"
    }
  }

  gpu = {
    ami_type       = "AL2023_x86_64_NVIDIA"
    instance_types = ["g5.xlarge"]
    desired_size   = 0
    min_size       = 0
    max_size       = 2
    disk_size      = 100
    capacity_type  = "ON_DEMAND"

    enable_bootstrap_user_data = false

    labels = {
      role        = "gpu"
      environment = "dev"
      workload    = "gpu"
    }

    taints = {
      gpu = {
        key    = "workload"
        value  = "gpu"
        effect = "NO_SCHEDULE"
      }
    }
  }
}

github_actions_role_arn = "arn:aws:iam::767398116920:role/solver-api-prod-github-actions"
