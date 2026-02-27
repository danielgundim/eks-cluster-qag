variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC provider do cluster EKS"
  type        = string
}

variable "batch_namespace" {
  description = "Namespace Kubernetes onde os jobs do Batch serão executados"
  type        = string
  default     = "aws-batch"
}

variable "batch_service_account" {
  description = "Nome do ServiceAccount Kubernetes para jobs do Batch"
  type        = string
  default     = "aws-batch-sa"
}

variable "tags" {
  description = "Tags comuns para os recursos"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_arn" {
  description = "ARN do cluster EKS"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o Compute Environment"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs dos Security Groups para o Compute Environment"
  type        = list(string)
}

variable "max_vcpus" {
  description = "Número máximo de vCPUs para o Compute Environment"
  type        = number
  default     = 8
}

variable "instance_types" {
  description = "Lista de tipos de instância EC2 para o Compute Environment do AWS Batch"
  type        = list(string)
  default     = ["optimal"]
}

variable "instance_profile_arn" {
  description = "ARN do Instance Profile para o Compute Environment do AWS Batch. Quando informado, evita descoberta dinâmica via instâncias EC2."
  type        = string
  default     = null

  validation {
    condition     = var.instance_profile_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:instance-profile/.+", var.instance_profile_arn))
    error_message = "instance_profile_arn deve ser nulo ou um ARN válido de instance-profile IAM."
  }
}

