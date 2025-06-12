#!/bin/bash

set -e

REPOSITORY="scispace/openmeter-helm"
AWS_REGION=us-west-2
ECR_REGISTRY="249531194221.dkr.ecr.$AWS_REGION.amazonaws.com"
CREATE_LATEST=false

# Parse command line arguments
for arg in "$@"; do
  if [ "$arg" = "--enable-latest" ]; then
    CREATE_LATEST=true
  fi
done

# Read version and templates
VERSION=$(cat version)
TAG_TEMPLATE=$(cat tag-templates/version-tag-template)
LATEST_TAG_TEMPLATE=$(cat tag-templates/latest-tag-template)

if [ -z "$VERSION" ] || [ -z "$TAG_TEMPLATE" ] || [ -z "$LATEST_TAG_TEMPLATE" ]; then
    echo "Error: Could not find version, version template, or latest tag template"
    exit 1
fi

# Replace version in template
VERSION_TAG=${TAG_TEMPLATE/\{VERSION\}/$VERSION}
LATEST_TAG=$LATEST_TAG_TEMPLATE

echo "Deploying Helm chart version $VERSION using templates:"
echo "  Version tag: $VERSION_TAG"
if [ "$CREATE_LATEST" = true ]; then
    echo "  Latest tag: $LATEST_TAG"
    echo "Latest tag will be pushed (--enable-latest flag provided)"
else
    echo "Latest tag will not be pushed (use --enable-latest flag to push it)"
fi

# Check if chart packages exist
TAGGED_PACKAGE="deploy/charts/${REPOSITORY//\//-}-$VERSION_TAG.tgz"
LATEST_PACKAGE="deploy/charts/${REPOSITORY//\//-}-$LATEST_TAG.tgz"

if [ ! -f "$TAGGED_PACKAGE" ]; then
    echo "Error: Chart package $TAGGED_PACKAGE not found"
    echo "Please run ./build.sh first"
    exit 1
fi

if [ "$CREATE_LATEST" = true ] && [ ! -f "$LATEST_PACKAGE" ]; then
    echo "Error: Latest chart package $LATEST_PACKAGE not found"
    echo "Please run ./build.sh --enable-latest first"
    exit 1
fi

# Authenticate with AWS ECR
echo "Logging into AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | helm registry login $ECR_REGISTRY --username AWS --password-stdin

# Create ECR repository if it doesn't exist
echo "Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names $REPOSITORY --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $REPOSITORY --region $AWS_REGION

# Push version-specific chart
echo "Pushing version-specific chart..."
helm push "$TAGGED_PACKAGE" "oci://$ECR_REGISTRY"

# Push latest chart if requested
if [ "$CREATE_LATEST" = true ]; then
    echo "Pushing latest chart..."
    helm push "$LATEST_PACKAGE" "oci://$ECR_REGISTRY"
fi

echo "Deploy completed successfully!"
echo "Charts pushed to ECR:"
echo "  - oci://$ECR_REGISTRY/$REPOSITORY:$VERSION_TAG"
if [ "$CREATE_LATEST" = true ]; then
    echo "  - oci://$ECR_REGISTRY/$REPOSITORY:$LATEST_TAG"
fi

echo ""
echo "To install from ECR, use:"
echo "  helm install openmeter oci://$ECR_REGISTRY/$REPOSITORY --version $VERSION_TAG"
if [ "$CREATE_LATEST" = true ]; then
    echo "  helm install openmeter oci://$ECR_REGISTRY/$REPOSITORY --version $LATEST_TAG"
fi 