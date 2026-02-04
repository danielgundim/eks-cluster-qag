variable "project_name" {
  description = "Nome do projeto."
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod)."
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

variable "single_nat_gateway" {
  description = "Usar apenas 1 NAT Gateway (economia de custos)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para recursos."
  type        = map(string)
  default     = {}
}
