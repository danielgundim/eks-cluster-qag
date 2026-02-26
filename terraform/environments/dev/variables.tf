variable "project_name" {
  description = "Nome do projeto: Quantum Algorithimics Group."
  type        = string
}

variable "aws_profile" {
  description = "AWS Profile a ser utilizado."
  type        = string
}

variable "region" {
  description = "Região AWS."
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes no EKS."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC."
  type        = string
}

variable "az_count" {
  description = "Quantidade de AZs."
  type        = number
}

variable "public_access_cidrs" {
  description = "CIDRs permitidos para acesso ao endpoint público do EKS."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar endpoint público do cluster."
  type        = bool
}

variable "node_instance_types" {
  description = "Tipos de instância para nodes."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Número desejado de nós."
  type        = number
}

variable "node_min_size" {
  description = "Mínimo de nós."
  type        = number
}

variable "node_max_size" {
  description = "Máximo de nós."
  type        = number
}

variable "github_actions_role_arn" {
  description = "ARN do IAM Role do GitHub Actions que terá acesso ao cluster EKS."
  type        = string
}

variable "github_actions_eks_access_policy_arn" {
  description = "ARN da policy de acesso EKS associada ao principal do GitHub Actions."
  type        = string
  default     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}
