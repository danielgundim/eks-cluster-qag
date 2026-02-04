output "vpc_id" {
  description = "ID da VPC."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs das subnets privadas."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs das subnets públicas."
  value       = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  description = "CIDR da VPC."
  value       = module.vpc.vpc_cidr_block
}
