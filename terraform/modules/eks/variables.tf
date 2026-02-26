variable "project_name" {
  description = "Nome do projeto."
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod)."
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes."
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar endpoint público."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs permitidos no endpoint público."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Tipos de instância para nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Número desejado de nós."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Mínimo de nós."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Máximo de nós."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Tamanho do disco (GB)."
  type        = number
  default     = 20
}

variable "node_capacity_type" {
  description = "Tipo de capacidade (ON_DEMAND ou SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_managed_node_groups" {
  description = "Mapa de node groups gerenciados do EKS. Quando vazio, usa fallback do node group base."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags para recursos."
  type        = map(string)
  default     = {}
}
