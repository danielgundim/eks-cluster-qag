# EKS + AWS Batch (QAG)

Infraestrutura Terraform para:
- VPC (subnets publicas/privadas em 3 AZs)
- Cluster EKS (node group gerenciado)
- Integracao AWS Batch com orquestracao EKS (compute environment + job queue)

## Estado atual (dev)
- Regiao: `us-east-1`
- Cluster: `qag-dev`
- Namespace Batch: `aws-batch`
- Compute Environment Batch: `qag-dev-batch-eks` (`VALID`)
- Job Queue Batch: `qag-dev-batch-queue` (`VALID`)

## Estrutura
```text
terraform/
  modules/
    vpc/
    eks/
    batch-eks/
  environments/
    dev/
k8s/
  aws-batch/
    namespace.yaml
    serviceaccount.yaml
    rbac.yaml
    batch-cluster-rbac.yaml
scripts/
  setup-batch-eks.sh
  validate-batch-setup.sh
docs/
  AWS_BATCH_SETUP.md
  BATCH_COMPUTE_ENV_CONFIG.json
```

## Fluxo oficial de setup
1. Autenticar AWS e atualizar kubeconfig:
```bash
aws sso login --profile tii
aws eks update-kubeconfig --region us-east-1 --name qag-dev --profile tii
```

2. Aplicar manifests Kubernetes do Batch:
```bash
kubectl apply -f k8s/aws-batch/namespace.yaml
kubectl apply -f k8s/aws-batch/serviceaccount.yaml
kubectl apply -f k8s/aws-batch/rbac.yaml
kubectl apply -f k8s/aws-batch/batch-cluster-rbac.yaml
```

3. Garantir mapeamento no `aws-auth` (ponto critico):
```bash
AWS_PROFILE=tii eksctl create iamidentitymapping \
  --cluster qag-dev \
  --region us-east-1 \
  --profile tii \
  --arn arn:aws:iam::767398116920:role/AWSServiceRoleForBatch \
  --username aws-batch \
  --group aws-batch-service \
  --no-duplicate-arns
```

4. Aplicar Terraform:
```bash
cd terraform/environments/dev
terraform init
terraform apply
```

## Validacao rapida
```bash
kubectl auth can-i get namespaces --as=aws-batch
kubectl auth can-i create pods -n aws-batch --as=aws-batch

cd terraform/environments/dev
terraform output batch_service_role_arn
terraform output batch_instance_profile_arn
```

## Observacao importante
- No campo `serviceRole` do Batch, o CE usa a **Service Linked Role**:
  `arn:aws:iam::767398116920:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch`
- No `aws-auth` do EKS, o mapeamento precisa ser criado com ARN **sem path**:
  `arn:aws:iam::767398116920:role/AWSServiceRoleForBatch`

Mais detalhes operacionais em `docs/AWS_BATCH_SETUP.md`.
