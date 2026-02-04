output "vpc_id" {
  description = "ID da VPC."
  value       = module.vpc.vpc_id
}

output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS."
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider para IRSA."
  value       = module.eks.oidc_provider_arn
}

output "region" {
  description = "Região AWS."
  value       = var.region
}

output "kubeconfig_command" {
  description = "Comando para configurar o kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# ====================================================
# AWS Batch Outputs
# ====================================================

output "batch_service_role_arn" {
  description = "ARN da Service Linked Role para o campo 'serviceRole' do AWS Batch Compute Environment"
  value       = module.batch_eks.batch_service_role_arn
}

output "batch_service_role_name" {
  description = "Nome da Service Linked Role do AWS Batch Compute Environment"
  value       = module.batch_eks.batch_service_role_name
}

output "batch_instance_profile_arn" {
  description = "ARN do Instance Profile para o campo 'instanceRole' do AWS Batch Compute Environment"
  value       = module.batch_eks.instance_profile_arn
}

output "batch_job_role_arn" {
  description = "ARN do IAM Role para os pods/jobs do AWS Batch (já configurado no ServiceAccount com IRSA)"
  value       = module.batch_eks.batch_job_role_arn
}

output "batch_namespace" {
  description = "Namespace Kubernetes para AWS Batch (use no campo 'Namespace' do Compute Environment)"
  value       = "aws-batch"
}

output "batch_service_account" {
  description = "ServiceAccount Kubernetes para AWS Batch"
  value       = "aws-batch-sa"
}

output "batch_compute_environment_arn" {
  description = "ARN do Compute Environment do AWS Batch"
  value       = module.batch_eks.compute_environment_arn
}

output "batch_compute_environment_name" {
  description = "Nome do Compute Environment do AWS Batch"
  value       = module.batch_eks.compute_environment_name
}

output "batch_job_queue_arn" {
  description = "ARN da Job Queue do AWS Batch"
  value       = module.batch_eks.job_queue_arn
}

output "batch_job_queue_name" {
  description = "Nome da Job Queue do AWS Batch"
  value       = module.batch_eks.job_queue_name
}
