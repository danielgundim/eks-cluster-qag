#!/bin/bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-tii}"
AWS_REGION="${AWS_REGION:-us-east-1}"
JOB_DEFINITION_NAME="${JOB_DEFINITION_NAME:-tii_qag_aws_batch_job_bqa_eks_gpu_feature_pipeline}"
IMAGE="${IMAGE:-767398116920.dkr.ecr.us-east-1.amazonaws.com/tii-qag/bqa:feature-pipeline-gpu-gpu-b42e220}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-aws-batch-sa}"
EXAMPLE_SCRIPT="${EXAMPLE_SCRIPT:-small_ibm_heavy_hex.py}"
CPU="${CPU:-1}"
MEMORY="${MEMORY:-2048Mi}"
GPU="${GPU:-1}"

PAYLOAD_FILE="$(mktemp /tmp/batch-eks-jobdef-XXXXXX.json)"

cat > "$PAYLOAD_FILE" <<JSON
{
  "jobDefinitionName": "$JOB_DEFINITION_NAME",
  "type": "container",
  "retryStrategy": {
    "attempts": 2
  },
  "eksProperties": {
    "podProperties": {
      "serviceAccountName": "$SERVICE_ACCOUNT",
      "containers": [
        {
          "name": "bqa",
          "image": "$IMAGE",
          "command": [
            "sh",
            "-c",
            "echo 'Started BQA process'; python3 /app/examples/$EXAMPLE_SCRIPT"
          ],
          "resources": {
            "requests": {
              "cpu": "$CPU",
              "memory": "$MEMORY",
              "nvidia.com/gpu": "$GPU"
            },
            "limits": {
              "cpu": "$CPU",
              "memory": "$MEMORY",
              "nvidia.com/gpu": "$GPU"
            }
          }
        }
      ]
    }
  },
  "propagateTags": false
}
JSON

aws batch register-job-definition \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --cli-input-json "file://$PAYLOAD_FILE"

echo "Registered EKS job definition: $JOB_DEFINITION_NAME"
