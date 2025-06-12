#!/bin/bash

set -e

REPOSITORY="scispace/openmeter-helm"
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

echo "Building Helm chart with version $VERSION using templates:"
echo "  Version tag: $VERSION_TAG"
if [ "$CREATE_LATEST" = true ]; then
    echo "  Latest tag: $LATEST_TAG"
    echo "Latest tag will be created (--enable-latest flag provided)"
else
    echo "Latest tag will not be created (use --enable-latest flag to create it)"
fi

# Ensure Chart.yaml version matches version file
CHART_VERSION=$(grep '^version:' deploy/charts/openmeter/Chart.yaml | awk '{print $2}')
if [ "$CHART_VERSION" != "$VERSION" ]; then
    echo "Error: Chart.yaml version ($CHART_VERSION) does not match version file ($VERSION)"
    echo "Updating Chart.yaml version to match version file..."
    sed -i.bak "s/^version:.*/version: $VERSION/" deploy/charts/openmeter/Chart.yaml
    sed -i.bak "s/^appVersion:.*/appVersion: \"v$VERSION\"/" deploy/charts/openmeter/Chart.yaml
    rm deploy/charts/openmeter/Chart.yaml.bak
    echo "Chart.yaml updated successfully"
fi

# Navigate to charts directory
cd deploy/charts

# Update chart dependencies
echo "Updating Helm chart dependencies..."
helm dependency update openmeter

# Lint the chart
echo "Linting Helm chart..."
helm lint openmeter

# Package the chart with version tag
echo "Packaging Helm chart..."
helm package openmeter --version "$VERSION" --app-version "v$VERSION"

# Rename the packaged chart to include our tag format
CHART_PACKAGE="openmeter-$VERSION.tgz"
TAGGED_PACKAGE="${REPOSITORY//\//-}-$VERSION_TAG.tgz"

if [ -f "$CHART_PACKAGE" ]; then
    mv "$CHART_PACKAGE" "$TAGGED_PACKAGE"
    echo "Chart packaged as: $TAGGED_PACKAGE"
else
    echo "Error: Expected chart package $CHART_PACKAGE not found"
    exit 1
fi

# Create latest tag if requested
if [ "$CREATE_LATEST" = true ]; then
    LATEST_PACKAGE="${REPOSITORY//\//-}-$LATEST_TAG.tgz"
    cp "$TAGGED_PACKAGE" "$LATEST_PACKAGE"
    echo "Latest chart created as: $LATEST_PACKAGE"
fi

# Return to root directory
cd ../..

echo "Build completed successfully!"
echo "Chart packages created:"
echo "  - deploy/charts/$TAGGED_PACKAGE"
if [ "$CREATE_LATEST" = true ]; then
    echo "  - deploy/charts/$LATEST_PACKAGE"
fi

echo ""
echo "To push to ECR, run:"
echo "  ./push_to_ecr.sh"
if [ "$CREATE_LATEST" = true ]; then
    echo "  ./push_to_ecr.sh --enable-latest"
fi 