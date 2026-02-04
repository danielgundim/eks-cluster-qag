# AWS Batch + EKS (estado atual validado)

Este guia reflete o ambiente real que esta funcionando hoje no projeto.

## Ambiente
- Conta AWS: `767398116920`
- Regiao: `us-east-1`
- Cluster EKS: `qag-dev`
- Namespace Batch: `aws-batch`
- ServiceAccount Batch: `aws-batch-sa`
- Compute Environment: `qag-dev-batch-eks`
- Job Queue: `qag-dev-batch-queue`

## Arquitetura aplicada
1. Terraform cria:
   - `aws_batch_compute_environment` (orquestracao EKS)
   - `aws_batch_job_queue`
   - IAM role IRSA dos jobs (`qag-dev-batch-job-role`)
2. Kubernetes aplica:
   - Namespace, ServiceAccount e RBAC de namespace
   - ClusterRole/ClusterRoleBinding para validacao do namespace
3. Autenticacao Batch no EKS:
   - via `aws-auth` (nao via `aws_eks_access_entry` para Service Linked Role)

## Ponto critico que destrava o erro de namespace
Para esse cenario, o AWS Batch usa a Service Linked Role:
- `arn:aws:iam::767398116920:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch`

No EKS `aws-auth`, o mapeamento precisa ser criado com ARN sem path:
- `arn:aws:iam::767398116920:role/AWSServiceRoleForBatch`
- `username: aws-batch`
- `group: aws-batch-service`

Se isso nao estiver assim, o CE fica `INVALID` com:
`Unable to validate Kubernetes Namespace [aws-batch]`.

## Setup completo
### 1) Login AWS + kubeconfig
```bash
aws sso login --profile tii
aws sts get-caller-identity --profile tii
aws eks update-kubeconfig --region us-east-1 --name qag-dev --profile tii
```

### 2) Aplicar manifests Kubernetes
```bash
kubectl apply -f k8s/aws-batch/namespace.yaml
kubectl apply -f k8s/aws-batch/serviceaccount.yaml
kubectl apply -f k8s/aws-batch/rbac.yaml
kubectl apply -f k8s/aws-batch/batch-cluster-rbac.yaml
```

### 3) Garantir mapping no aws-auth
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

Se ja existir mapping com ARN path-based, remova e recrie:
```bash
AWS_PROFILE=tii eksctl delete iamidentitymapping \
  --cluster qag-dev \
  --region us-east-1 \
  --profile tii \
  --arn arn:aws:iam::767398116920:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch
```

### 4) Aplicar Terraform
```bash
cd terraform/environments/dev
terraform init
terraform apply
```

## Validacao
### Kubernetes/RBAC
```bash
kubectl auth can-i get namespaces --as=aws-batch
kubectl auth can-i create pods -n aws-batch --as=aws-batch
```
Esperado: `yes` para ambos.

### Batch
```bash
aws batch describe-compute-environments \
  --compute-environments qag-dev-batch-eks \
  --region us-east-1 \
  --profile tii \
  --query 'computeEnvironments[0].{status:status,state:state,statusReason:statusReason}'

aws batch describe-job-queues \
  --job-queues qag-dev-batch-queue \
  --region us-east-1 \
  --profile tii \
  --query 'jobQueues[0].{status:status,state:state,statusReason:statusReason}'
```
Esperado:
- CE: `VALID`, `ENABLED`, `ComputeEnvironment Healthy`
- Queue: `VALID`, `ENABLED`, `JobQueue Healthy`

## Outputs Terraform uteis
```bash
cd terraform/environments/dev
terraform output batch_service_role_arn
terraform output batch_instance_profile_arn
terraform output batch_job_role_arn
terraform output batch_namespace
terraform output batch_service_account
```

## Scripts do repositorio
- Setup assistido: `scripts/setup-batch-eks.sh`
- Validacao completa: `scripts/validate-batch-setup.sh`

## Referencia de payload
Exemplo alinhado com o ambiente atual: `docs/BATCH_COMPUTE_ENV_CONFIG.json`.
