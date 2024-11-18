#!/bin/bash

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"  # Change to your region
ECR_REPO_NAME="bm-factorio-image"

# Get the current git commit hash
GIT_COMMIT=$(git rev-parse --short HEAD)

# Install QEMU emulators
docker run --privileged --rm tonistiigi/binfmt --install all

# Create and use a new builder that supports multi-architecture builds
docker buildx create --name multiarch-builder --use

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push the image directly with buildx
docker buildx build \
  --platform linux/amd64 \
  --push \
  -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${GIT_COMMIT} \
  -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest \
  .