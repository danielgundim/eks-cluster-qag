output "instance_profile_arn" {
  description = "ARN do Instance Profile para o campo 'instanceRole' do AWS Batch Compute Environment"
  value       = local.instance_profile_arn
}

output "batch_service_role_arn" {
  description = "ARN da Service Linked Role para o campo 'serviceRole' do AWS Batch Compute Environment"
  value       = data.aws_iam_role.batch_service_linked_role.arn
}

output "batch_service_role_name" {
  description = "Nome da Service Linked Role do AWS Batch"
  value       = data.aws_iam_role.batch_service_linked_role.name
}

output "batch_job_role_arn" {
  description = "ARN do IAM Role para os pods do AWS Batch (IRSA) - usar no ServiceAccount"
  value       = aws_iam_role.batch_eks_job_role.arn
}

output "batch_job_role_name" {
  description = "Nome do IAM Role para os pods do AWS Batch"
  value       = aws_iam_role.batch_eks_job_role.name
}

output "compute_environment_arn" {
  description = "ARN do Compute Environment do AWS Batch"
  value       = aws_batch_compute_environment.eks.arn
}

output "compute_environment_name" {
  description = "Nome do Compute Environment do AWS Batch"
  value       = aws_batch_compute_environment.eks.name
}

output "job_queue_arn" {
  description = "ARN da Job Queue do AWS Batch"
  value       = aws_batch_job_queue.eks.arn
}

output "job_queue_name" {
  description = "Nome da Job Queue do AWS Batch"
  value       = aws_batch_job_queue.eks.name
}
