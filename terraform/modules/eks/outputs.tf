output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "CA do cluster (base64)."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider."
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  description = "Security group do cluster."
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group dos nodes."
  value       = module.eks.node_security_group_id
}

output "cluster_arn" {
  description = "ARN do cluster EKS."
  value       = module.eks.cluster_arn
}
