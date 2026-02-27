#!/bin/bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-tii}"
AWS_REGION="${AWS_REGION:-us-east-1}"
JOB_DEFINITION_NAME="${JOB_DEFINITION_NAME:-tii_qag-aws_batch_job_bqa_eks}"
IMAGE="${IMAGE:-767398116920.dkr.ecr.us-east-1.amazonaws.com/tii-qag/bqa:sha-7cac485}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-aws-batch-sa}"

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
            "echo 'Started BQA process'; python3 /app/examples/full_size_ibm_heavy_hex.py"
          ],
          "resources": {
            "requests": {
              "cpu": "1",
              "memory": "2048Mi"
            },
            "limits": {
              "cpu": "1",
              "memory": "2048Mi"
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
