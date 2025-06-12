# OpenMeter Helm Charts

This repository contains Helm chart build configurations and scripts to create and deploy enhanced versions of the OpenMeter chart to Amazon ECR.

## Overview

The repository provides a streamlined way to build and deploy OpenMeter Helm charts to Amazon ECR. It supports versioned and latest tags and maintains a robust build pipeline with automated quality checks.

## Requirements

- Helm 3.8+ installed and configured
- AWS CLI installed and configured with appropriate credentials
- Access to the target ECR repository
- kubectl configured for Kubernetes cluster access
- Go 1.21+ (specified in `go.mod`)

## Repository Structure

```
.
├── deploy/
│   └── charts/
│       └── openmeter/
│           ├── Chart.yaml              # Chart version and metadata
│           ├── values.yaml             # Chart configuration values
│           ├── templates/
│           │   └── ...                # OpenMeter templates
│           └── charts/                # Chart dependencies
├── tag-templates/
│   ├── version-tag-template           # Template for version-specific tags
│   └── latest-tag-template            # Template for latest tags
├── patches/
│   └── README.md                      # Patch documentation
├── hooks/
│   ├── pre-commit                     # Git pre-commit hook
│   └── README.md                      # Hooks documentation
├── version                            # Contains semantic version (e.g., 1.0.0-beta.213)
├── build.sh                           # Script to build Helm charts
├── push_to_ecr.sh                     # Script to deploy charts to ECR
├── setup-hooks.sh                     # Script to configure Git hooks
├── Makefile                           # Build and development commands
└── BUILD_FLOW.md                      # Comprehensive build documentation
```

## Versioning System

The repository uses a flexible template-based versioning system:

1. `version`: Contains the semantic version number (e.g., `1.0.0-beta.213`)
2. `tag-templates/version-tag-template`: Template for version-specific tags
3. `tag-templates/latest-tag-template`: Template for latest tags
4. `deploy/charts/openmeter/Chart.yaml`: Chart version automatically synced with version file

The templates use placeholders that are automatically replaced during build:

- `{VERSION}` is replaced with the content of the `version` file

**Current Templates:**

- Version template: `{VERSION}`
- Latest template: `latest`

For example, with version `1.0.0-beta.213`, the tags would be:

- `1.0.0-beta.213`
- `latest` (when using `--enable-latest`)

The packaged charts are named:

- `scispace-openmeter-helm-1.0.0-beta.213.tgz`
- `scispace-openmeter-helm-latest.tgz` (when using `--enable-latest`)

## Git Hooks

The repository includes Git hooks to enforce version management and chart quality:

### Setup Hooks

```bash
./setup-hooks.sh
```

This configures Git to use the project's hooks, including:

- **pre-commit**: Ensures the version file is updated, validates Helm chart syntax, and checks version consistency

## Usage

### AWS Profile Configuration

If you have multiple AWS CLI profiles configured, make sure to set the `AWS_PROFILE` environment variable before running the deploy script:

```bash
export AWS_PROFILE=your-profile-name
```

### Building Charts

To build and package the Helm charts:

```bash
# Build version-specific chart only
./build.sh

# Build version-specific chart and latest chart
./build.sh --enable-latest
```

This will:

1. Read the semantic version and templates
2. Update chart dependencies
3. Lint the Helm chart for syntax validation
4. Package the chart with version-specific tags
5. Optionally create latest tagged chart (with `--enable-latest` flag)

### Deploying to ECR

To deploy the built charts to Amazon ECR:

```bash
# If using a specific AWS profile
export AWS_PROFILE=your-profile-name

# Deploy version-specific chart only
./push_to_ecr.sh

# Deploy version-specific chart and latest chart
./push_to_ecr.sh --enable-latest
```

This will:

1. Authenticate with AWS ECR
2. Create ECR repository if it doesn't exist
3. Push version-specific chart to ECR
4. Optionally push latest chart (with `--enable-latest` flag)

The charts will be pushed to:

```
249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm
```

### Installing from ECR

To install the chart from ECR:

```bash
# Install specific version
helm install openmeter oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm --version 1.0.0-beta.213

# Install latest version
helm install openmeter oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm --version latest
```

## Chart Tags

### Version-Specific Tags (Always Created)

- Chart: e.g., `1.0.0-beta.213`

### Latest Tags (Created with --enable-latest)

- Latest Chart: `latest`

## Patches

The repository includes patches for OpenMeter components located in the `patches/` directory. These patches are automatically applied during the chart build process.

## Make Commands

The repository includes convenient Make targets:

```bash
# Setup and development
make setup-dev              # Setup hooks and dependencies
make helm-lint              # Validate chart syntax
make helm-test              # Dry-run test

# Building
make helm-build             # Build version-specific chart
make helm-build-latest      # Build with latest tag

# Deployment
make helm-deploy            # Build and push to ECR
make helm-deploy-latest     # Build and push with latest tag
```

## Restrictions

1. **AWS Region**: Currently configured for `us-west-2`. To use a different region, modify `AWS_REGION` in `push_to_ecr.sh`
2. **ECR Repository**: Hardcoded to use account `249531194221`. Update `ECR_REGISTRY` in `push_to_ecr.sh` if using a different account
3. **Helm Version**: Requires Helm 3.8+ for OCI registry support
4. **Kubernetes Version**: Compatible with Kubernetes 1.24+

## Development

### Setting Up Development Environment

1. Clone the repository
2. Set up Git hooks: `./setup-hooks.sh`
3. Update dependencies: `make helm-deps`
4. Ensure Helm and AWS CLI are configured

### Updating Versions

1. Update the semantic version in `version` file (e.g., `1.0.0-beta.213` → `1.0.0-beta.214`)
2. The pre-commit hook will ensure you've updated the version before committing
3. The hook will also validate Chart.yaml version matches the version file
4. Update tag templates in `tag-templates/` if needed
5. Run `make helm-build-latest` to create new charts
6. Run `make helm-push-latest` to push to ECR

### Modifying Tag Templates

You can customize the tagging scheme by editing:

- `tag-templates/version-tag-template`: For version-specific tags
- `tag-templates/latest-tag-template`: For latest tags

### Testing Changes

```bash
# Lint chart
make helm-lint

# Test with dry-run
make helm-test

# Validate version consistency
cat version
grep '^version:' deploy/charts/openmeter/Chart.yaml
```

## Security Notes

- Ensure AWS credentials are properly configured with minimal required permissions
- Do not commit AWS credentials or sensitive information to the repository
- Keep chart dependencies updated for security patches
- The pre-commit hook helps prevent accidental commits without version updates

## Contributing

When contributing to this repository:

1. Set up Git hooks using `./setup-hooks.sh`
2. Update chart templates and values when making changes
3. Test changes with both local and ECR deployments
4. Update version files according to semantic versioning principles
5. The pre-commit hook will ensure version consistency and chart validation
6. Update documentation for new features
