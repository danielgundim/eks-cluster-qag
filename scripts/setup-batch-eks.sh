#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=============================================="
echo "AWS Batch + EKS - Setup Completo"
echo "=============================================="
echo ""

# Verificar se o cluster está acessível
echo "1️⃣  Verificando acesso ao cluster EKS..."
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ Erro: Cluster não acessível. Execute: aws eks update-kubeconfig --region us-east-1 --name qag-dev --profile tii"
    exit 1
fi
echo "✅ Cluster acessível"
echo ""

# Aplicar manifests Kubernetes necessários para AWS Batch
echo "2️⃣  Aplicando namespace e RBAC para AWS Batch..."
kubectl apply -f "$PROJECT_ROOT/k8s/aws-batch/namespace.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/aws-batch/rbac.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/aws-batch/batch-cluster-rbac.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/aws-batch/serviceaccount.yaml"
echo "✅ Namespace e RBAC aplicados"
echo ""

# Aplicar Terraform
echo "3️⃣  Aplicando Terraform para criar recursos do Batch no AWS..."
cd "$PROJECT_ROOT/terraform/environments/dev"
terraform init -upgrade
terraform apply

echo ""
echo "=============================================="
echo "✅ Setup Completo!"
echo "=============================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Validar status do Compute Environment:"
echo "   aws batch describe-compute-environments --compute-environments qag-dev-batch-eks --region us-east-1 --profile tii --query 'computeEnvironments[0].{status:status,state:state,statusReason:statusReason}'"
echo ""
echo "2. Obtenha a Service Role ARN:"
echo "   terraform output batch_service_role_arn"
echo ""
echo "3. Obtenha o Instance Profile ARN:"
echo "   terraform output batch_instance_profile_arn"
echo ""
echo "4. Garanta o mapeamento no aws-auth:"
echo "   arn:aws:iam::<ACCOUNT_ID>:role/AWSServiceRoleForBatch -> username: aws-batch"
echo "   Exemplo:"
echo "   AWS_PROFILE=tii eksctl create iamidentitymapping --cluster qag-dev --region us-east-1 --profile tii --arn arn:aws:iam::<ACCOUNT_ID>:role/AWSServiceRoleForBatch --username aws-batch --group aws-batch-service --no-duplicate-arns"
echo ""
echo "5. Rodar validacao completa:"
echo "   ./scripts/validate-batch-setup.sh"
echo ""
