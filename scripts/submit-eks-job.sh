#!/bin/bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-tii}"
AWS_REGION="${AWS_REGION:-us-east-1}"
JOB_QUEUE="${JOB_QUEUE:-qag-dev-batch-queue}"
JOB_DEFINITION="${JOB_DEFINITION:-tii_qag_aws_batch_job_bqa_eks_gpu_feature_pipeline:6}"
JOB_NAME_PREFIX="${JOB_NAME_PREFIX:-gpu-rev6-run}"
WAIT_FOR_COMPLETION="${WAIT_FOR_COMPLETION:-false}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-15}"

JOB_NAME="${JOB_NAME_PREFIX}-$(date +%s)"

JOB_ID="$(aws batch submit-job \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --job-name "$JOB_NAME" \
  --job-queue "$JOB_QUEUE" \
  --job-definition "$JOB_DEFINITION" \
  --query 'jobId' \
  --output text)"

echo "Submitted job"
echo "  jobName: $JOB_NAME"
echo "  jobId:   $JOB_ID"
echo "  queue:   $JOB_QUEUE"
echo "  def:     $JOB_DEFINITION"

if [[ "$WAIT_FOR_COMPLETION" != "true" ]]; then
  exit 0
fi

echo "Waiting for completion..."
while true; do
  STATUS="$(aws batch describe-jobs \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --jobs "$JOB_ID" \
    --query 'jobs[0].status' \
    --output text)"

  echo "  status: $STATUS"

  if [[ "$STATUS" == "SUCCEEDED" ]]; then
    echo "Job completed successfully"
    exit 0
  fi

  if [[ "$STATUS" == "FAILED" ]]; then
    REASON="$(aws batch describe-jobs \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE" \
      --jobs "$JOB_ID" \
      --query 'jobs[0].container.reason' \
      --output text)"
    echo "Job failed: $REASON"
    exit 1
  fi

  sleep "$POLL_INTERVAL_SECONDS"
done
