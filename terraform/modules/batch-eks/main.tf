# ====================================================
# Data Sources
# ====================================================

# OIDC provider para IRSA
data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

# Service Linked Role usada pelo AWS Batch no Compute Environment
data "aws_iam_role" "batch_service_linked_role" {
  name = "AWSServiceRoleForBatch"
}

# Buscar instâncias do EKS para obter o Instance Profile ARN
data "aws_instances" "eks_nodes" {
  count = var.instance_profile_arn == null ? 1 : 0

  filter {
    name   = "tag:eks:cluster-name"
    values = [var.cluster_name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Buscar detalhes da primeira instância para obter o Instance Profile
data "aws_instance" "eks_node" {
  count       = var.instance_profile_arn == null && length(data.aws_instances.eks_nodes[0].ids) > 0 ? 1 : 0
  instance_id = data.aws_instances.eks_nodes[0].ids[0]
}

# Buscar o Instance Profile completo (para obter o ARN válido)
data "aws_iam_instance_profile" "eks_node" {
  count = var.instance_profile_arn == null && length(data.aws_instance.eks_node) > 0 ? 1 : 0
  name  = data.aws_instance.eks_node[0].iam_instance_profile
}

locals {
  oidc_provider_url = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")

  # Instance Profile ARN informado explicitamente ou extraído da instância EC2 do node
  instance_profile_arn = var.instance_profile_arn != null ? var.instance_profile_arn : (length(data.aws_iam_instance_profile.eks_node) > 0 ? data.aws_iam_instance_profile.eks_node[0].arn : null)
}

# ====================================================
# 1) IAM Role para os Pods do AWS Batch (IRSA)
# ====================================================

# Trust Policy: permite que o ServiceAccount aws-batch-sa assuma o role
data "aws_iam_policy_document" "batch_eks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.batch_namespace}:${var.batch_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "batch_eks_job_role" {
  name               = "${var.cluster_name}-batch-job-role"
  assume_role_policy = data.aws_iam_policy_document.batch_eks_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-batch-job-role"
      Purpose = "aws-batch-eks-jobs"
    }
  )
}

# ====================================================
# 2) Policies necessárias para o Job Role
# ====================================================

# Policy para acesso ao ECR (pull de imagens)
data "aws_iam_policy_document" "batch_ecr_access" {
  statement {
    sid    = "ECRReadOnly"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "batch_ecr_access" {
  name        = "${var.cluster_name}-batch-ecr-access"
  description = "Permite que jobs do AWS Batch no EKS façam pull de imagens do ECR"
  policy      = data.aws_iam_policy_document.batch_ecr_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "batch_ecr_access" {
  role       = aws_iam_role.batch_eks_job_role.name
  policy_arn = aws_iam_policy.batch_ecr_access.arn
}

# Policy para logs (CloudWatch)
data "aws_iam_policy_document" "batch_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "batch_logs" {
  name        = "${var.cluster_name}-batch-logs"
  description = "Permite que jobs do Batch enviem logs para CloudWatch"
  policy      = data.aws_iam_policy_document.batch_logs.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "batch_logs" {
  role       = aws_iam_role.batch_eks_job_role.name
  policy_arn = aws_iam_policy.batch_logs.arn
}

# ====================================================
# 3) AWS Batch Compute Environment
# ====================================================

resource "aws_batch_compute_environment" "eks" {
  name         = "${var.cluster_name}-batch-eks"
  type         = "MANAGED"
  state        = "ENABLED"
  service_role = data.aws_iam_role.batch_service_linked_role.arn

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = var.max_vcpus
    instance_type       = var.instance_types
    subnets             = var.private_subnet_ids
    security_group_ids  = var.security_group_ids
    instance_role       = local.instance_profile_arn
  }

  eks_configuration {
    eks_cluster_arn      = var.eks_cluster_arn
    kubernetes_namespace = var.batch_namespace
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-batch-eks-compute-env"
      Purpose = "aws-batch-eks-integration"
    }
  )

  lifecycle {
    precondition {
      condition     = local.instance_profile_arn != null
      error_message = "Nenhum worker node em execução foi encontrado no cluster EKS. O AWS Batch precisa do Instance Profile ARN dos nodes para criar o Compute Environment."
    }
  }

}

# ====================================================
# 4) AWS Batch Job Queue
# ====================================================

resource "aws_batch_job_queue" "eks" {
  name     = "${var.cluster_name}-batch-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.eks.arn
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-batch-job-queue"
      Purpose = "aws-batch-eks-integration"
    }
  )
}

