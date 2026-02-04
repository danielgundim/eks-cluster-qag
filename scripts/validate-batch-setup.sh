#!/bin/bash

# Script de Validação AWS Batch + EKS
# Valida todos os componentes necessários antes de criar o Compute Environment

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
CLUSTER_NAME="qag-dev"
NAMESPACE="aws-batch"
SERVICE_ACCOUNT="aws-batch-sa"
AWS_PROFILE="tii"
AWS_ACCOUNT="767398116920"
SERVICE_ROLE_NAME="AWSServiceRoleForBatch"
JOB_ROLE_NAME="qag-dev-batch-job-role"
# No aws-auth, o rolearn deve ser sem path (limitação do EKS auth ConfigMap)
SERVICE_ROLE_ARN_AWS_AUTH="arn:aws:iam::${AWS_ACCOUNT}:role/${SERVICE_ROLE_NAME}"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  AWS Batch + EKS - Validação de Componentes${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Função para printar status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅ OK${NC} - $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC} - $message"
    else
        echo -e "${RED}❌ FAIL${NC} - $message"
    fi
}

# Contador de erros
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 1. Validando acesso ao cluster EKS...${NC}"
if kubectl cluster-info &> /dev/null; then
    CLUSTER_ENDPOINT=$(kubectl cluster-info | head -n1 | awk '{print $NF}')
    print_status "OK" "Conectado ao cluster: $CLUSTER_ENDPOINT"
else
    print_status "FAIL" "Não conseguiu conectar ao cluster EKS"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: Verifique o kubeconfig e execute 'aws eks update-kubeconfig --name $CLUSTER_NAME --profile $AWS_PROFILE'${NC}"
fi
echo ""

echo -e "${BLUE}🔍 2. Validando namespace '$NAMESPACE'...${NC}"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    NS_STATUS=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$NS_STATUS" = "Active" ]; then
        print_status "OK" "Namespace '$NAMESPACE' existe e está ativo"
    else
        print_status "WARN" "Namespace '$NAMESPACE' existe mas status é: $NS_STATUS"
        ((WARNINGS++))
    fi
else
    print_status "FAIL" "Namespace '$NAMESPACE' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/namespace.yaml${NC}"
fi
echo ""

echo -e "${BLUE}🔍 3. Validando ServiceAccount com IRSA...${NC}"
if kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" &> /dev/null; then
    ROLE_ARN=$(kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null || echo "")
    
    if [ -n "$ROLE_ARN" ]; then
        print_status "OK" "ServiceAccount '$SERVICE_ACCOUNT' tem anotação IRSA: $ROLE_ARN"
    else
        print_status "FAIL" "ServiceAccount '$SERVICE_ACCOUNT' existe mas não tem anotação IRSA"
        ((ERRORS++))
        echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/serviceaccount.yaml${NC}"
    fi
else
    print_status "FAIL" "ServiceAccount '$SERVICE_ACCOUNT' não existe no namespace '$NAMESPACE'"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/serviceaccount.yaml${NC}"
fi
echo ""

echo -e "${BLUE}🔍 4. Validando RBAC namespace-scoped...${NC}"
if kubectl get role aws-batch-job-role -n "$NAMESPACE" &> /dev/null; then
    print_status "OK" "Role 'aws-batch-job-role' existe no namespace"
else
    print_status "FAIL" "Role 'aws-batch-job-role' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/rbac.yaml${NC}"
fi

if kubectl get rolebinding aws-batch-job-rolebinding -n "$NAMESPACE" &> /dev/null; then
    print_status "OK" "RoleBinding 'aws-batch-job-rolebinding' existe no namespace"
else
    print_status "FAIL" "RoleBinding 'aws-batch-job-rolebinding' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/rbac.yaml${NC}"
fi
echo ""

echo -e "${BLUE}🔍 5. Validando ClusterRole para AWS Batch (essencial!)...${NC}"
if kubectl get clusterrole aws-batch-cluster-role &> /dev/null; then
    print_status "OK" "ClusterRole 'aws-batch-cluster-role' existe"
else
    print_status "FAIL" "ClusterRole 'aws-batch-cluster-role' não existe - CAUSA DO ERRO 'Unable to validate namespace'"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/batch-cluster-rbac.yaml${NC}"
fi

if kubectl get clusterrolebinding aws-batch-cluster-binding &> /dev/null; then
    BINDING_SUBJECT=$(kubectl get clusterrolebinding aws-batch-cluster-binding -o jsonpath='{.subjects[0].name}')
    print_status "OK" "ClusterRoleBinding 'aws-batch-cluster-binding' existe"
    echo -e "   └─ Vinculado a: $BINDING_SUBJECT"
else
    print_status "FAIL" "ClusterRoleBinding 'aws-batch-cluster-binding' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: kubectl apply -f k8s/aws-batch/batch-cluster-rbac.yaml${NC}"
fi
echo ""

echo -e "${BLUE}🔍 6. Validando IAM Service Role...${NC}"
if aws iam get-role --role-name "$SERVICE_ROLE_NAME" --profile "$AWS_PROFILE" &> /dev/null; then
    SERVICE_ROLE_ARN=$(aws iam get-role --role-name "$SERVICE_ROLE_NAME" --profile "$AWS_PROFILE" --query 'Role.Arn' --output text)
    print_status "OK" "Service Role '$SERVICE_ROLE_NAME' existe"
    echo -e "   └─ ARN: $SERVICE_ROLE_ARN"
    
    # Verificar policies anexadas
    POLICIES=$(aws iam list-attached-role-policies --role-name "$SERVICE_ROLE_NAME" --profile "$AWS_PROFILE" --query 'AttachedPolicies[*].PolicyName' --output text)
    if [ -n "$POLICIES" ]; then
        echo -e "   └─ Policies anexadas: $POLICIES"
    fi
else
    print_status "FAIL" "Service Role '$SERVICE_ROLE_NAME' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: cd terraform/environments/dev && terraform apply${NC}"
fi
echo ""

echo -e "${BLUE}🔍 7. Validando IAM Job Role (IRSA)...${NC}"
if aws iam get-role --role-name "$JOB_ROLE_NAME" --profile "$AWS_PROFILE" &> /dev/null; then
    JOB_ROLE_ARN=$(aws iam get-role --role-name "$JOB_ROLE_NAME" --profile "$AWS_PROFILE" --query 'Role.Arn' --output text)
    print_status "OK" "Job Role '$JOB_ROLE_NAME' existe"
    echo -e "   └─ ARN: $JOB_ROLE_ARN"
    
    # Verificar trust policy (OIDC)
    TRUST_POLICY=$(aws iam get-role --role-name "$JOB_ROLE_NAME" --profile "$AWS_PROFILE" --query 'Role.AssumeRolePolicyDocument' --output json)
    if echo "$TRUST_POLICY" | grep -q "oidc.eks"; then
        print_status "OK" "Trust policy configurado para OIDC (IRSA)"
    else
        print_status "WARN" "Trust policy pode não estar configurado corretamente para IRSA"
        ((WARNINGS++))
    fi
else
    print_status "FAIL" "Job Role '$JOB_ROLE_NAME' não existe"
    ((ERRORS++))
    echo -e "${YELLOW}   Solução: cd terraform/environments/dev && terraform apply${NC}"
fi
echo ""

echo -e "${BLUE}🔍 8. Validando aws-auth mapping para AWS Batch...${NC}"
if kubectl get configmap aws-auth -n kube-system &> /dev/null; then
    AWS_AUTH_CONTENT=$(kubectl get configmap aws-auth -n kube-system -o yaml)

    if echo "$AWS_AUTH_CONTENT" | grep -q "$SERVICE_ROLE_ARN_AWS_AUTH" && echo "$AWS_AUTH_CONTENT" | grep -q "username: aws-batch"; then
        print_status "OK" "aws-auth contém mapeamento do AWS Batch (role + username aws-batch)"
        echo -e "   └─ rolearn: $SERVICE_ROLE_ARN_AWS_AUTH"
    else
        print_status "FAIL" "aws-auth NÃO contém mapeamento correto para o AWS Batch"
        ((ERRORS++))
        echo -e "${YELLOW}   Solução: mapear role no aws-auth:${NC}"
        echo -e "${YELLOW}   rolearn: $SERVICE_ROLE_ARN_AWS_AUTH${NC}"
        echo -e "${YELLOW}   username: aws-batch${NC}"
    fi
else
    print_status "FAIL" "ConfigMap aws-auth não encontrado no namespace kube-system"
    ((ERRORS++))
fi
echo ""

echo -e "${BLUE}🔍 9. Validando Instance Profile...${NC}"
INSTANCE_IDS=$(aws ec2 describe-instances --profile "$AWS_PROFILE" \
    --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    INSTANCE_PROFILE_ARN=$(aws ec2 describe-instances --profile "$AWS_PROFILE" \
        --instance-ids $(echo $INSTANCE_IDS | awk '{print $1}') \
        --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCE_PROFILE_ARN" ] && [ "$INSTANCE_PROFILE_ARN" != "None" ]; then
        print_status "OK" "Instance Profile encontrado nos worker nodes"
        echo -e "   └─ ARN: $INSTANCE_PROFILE_ARN"
    else
        print_status "WARN" "Não foi possível obter o Instance Profile"
        ((WARNINGS++))
    fi
else
    print_status "WARN" "Nenhuma instância EC2 encontrada com a tag eks:cluster-name=$CLUSTER_NAME"
    ((WARNINGS++))
fi
echo ""

echo -e "${BLUE}🔍 10. Resumo dos valores atuais do ambiente...${NC}"
echo ""
echo -e "${GREEN}📋 Valores de referencia do ambiente:${NC}"
echo ""

if [ -n "$SERVICE_ROLE_ARN" ]; then
    echo -e "${YELLOW}Service role ARN:${NC}"
    echo -e "  $SERVICE_ROLE_ARN"
else
    echo -e "${RED}Service role ARN: NÃO DISPONÍVEL (execute terraform apply)${NC}"
fi

echo ""

if [ -n "$INSTANCE_PROFILE_ARN" ]; then
    echo -e "${YELLOW}Instance role ARN:${NC}"
    echo -e "  $INSTANCE_PROFILE_ARN"
else
    echo -e "${RED}Instance role ARN: NÃO DISPONÍVEL${NC}"
fi

echo ""
echo -e "${YELLOW}Namespace:${NC}"
echo -e "  $NAMESPACE"

echo ""
echo -e "${YELLOW}Subnets (privadas apenas):${NC}"
PRIVATE_SUBNETS=$(aws ec2 describe-subnets --profile "$AWS_PROFILE" \
    --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" \
              "Name=tag:kubernetes.io/role/internal-elb,Values=1" \
    --query 'Subnets[*].SubnetId' \
    --output text 2>/dev/null || echo "")

if [ -n "$PRIVATE_SUBNETS" ]; then
    for subnet in $PRIVATE_SUBNETS; do
        echo -e "  $subnet"
    done
else
    echo -e "${RED}  NÃO FOI POSSÍVEL LISTAR AS SUBNETS${NC}"
fi

echo ""
echo -e "${YELLOW}Security Group:${NC}"
NODE_SG=$(aws eks describe-cluster --name "$CLUSTER_NAME" --profile "$AWS_PROFILE" \
    --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' \
    --output text 2>/dev/null || echo "")

if [ -n "$NODE_SG" ] && [ "$NODE_SG" != "None" ]; then
    echo -e "  $NODE_SG"
else
    echo -e "${RED}  NÃO FOI POSSÍVEL OBTER O SECURITY GROUP${NC}"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Resultado da Validação${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ SUCESSO!${NC} Todos os componentes estão configurados corretamente."
    echo -e "${GREEN}   Você pode criar o Compute Environment no AWS Batch Console.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  AVISOS: $WARNINGS warning(s) encontrado(s).${NC}"
    echo -e "${YELLOW}   Revise os avisos acima, mas você provavelmente pode prosseguir.${NC}"
    exit 0
else
    echo -e "${RED}❌ FALHAS: $ERRORS erro(s) crítico(s) encontrado(s).${NC}"
    echo -e "${RED}   Corrija os erros acima antes de criar o Compute Environment.${NC}"
    echo ""
    echo -e "${YELLOW}📚 Soluções rápidas:${NC}"
    echo -e "${YELLOW}   1. kubectl apply -f k8s/aws-batch/batch-cluster-rbac.yaml${NC}"
    echo -e "${YELLOW}   2. kubectl apply -f k8s/aws-batch/namespace.yaml${NC}"
    echo -e "${YELLOW}   3. kubectl apply -f k8s/aws-batch/rbac.yaml${NC}"
    echo -e "${YELLOW}   4. kubectl apply -f k8s/aws-batch/serviceaccount.yaml${NC}"
    echo -e "${YELLOW}   5. cd terraform/environments/dev && terraform apply${NC}"
    exit 1
fi
