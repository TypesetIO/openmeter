# OpenMeter Helm Chart Build Flow

This document describes the complete build and deployment flow for the OpenMeter Helm chart, similar to the scispace-langgraph-api repository.

## 🏗️ Build System Overview

The build system provides automated packaging and deployment of OpenMeter Helm charts to AWS ECR with version management and Git hooks for quality control.

## 📁 Build System Structure

```
openmeter/
├── 📄 version                           # Semantic version (e.g., 1.0.0-beta.213)
├── 📄 setup-hooks.sh                    # Git hooks configuration script
├── 📄 build.sh                         # Chart build and packaging script
├── 📄 push_to_ecr.sh                   # ECR deployment script
├── 📂 tag-templates/
│   ├── 📄 version-tag-template          # Version tag format: {VERSION}
│   └── 📄 latest-tag-template           # Latest tag format: latest
├── 📂 hooks/
│   ├── 📄 pre-commit                    # Git pre-commit validation
│   └── 📄 README.md                    # Hooks documentation
└── 📂 patches/
    └── 📄 README.md                     # Patch documentation
```

## 🔄 Development Workflow

### 1. Initial Setup

```bash
# Clone repository and setup development environment
git clone <repository-url>
cd openmeter

# Setup Git hooks and dependencies
make setup-dev
```

### 2. Making Changes

1. **Modify Helm Charts**: Update templates in `deploy/charts/openmeter/templates/`
2. **Update Configuration**: Modify `deploy/charts/openmeter/values.yaml`
3. **Test Locally**: Run `make helm-test` for dry-run validation

### 3. Version Management

```bash
# Update version for new release
echo "1.0.0-beta.214" > version

# Git hooks will automatically validate:
# - Version file has been updated
# - Chart.yaml version matches version file
# - Helm chart syntax is valid
```

### 4. Build and Deploy

```bash
# Build chart package
make helm-build

# Build with latest tag
make helm-build-latest

# Deploy to ECR
make helm-deploy

# Deploy with latest tag
make helm-deploy-latest
```

## 🛠️ Build Commands

### Core Build Commands

| Command                  | Description             | Output                                         |
| ------------------------ | ----------------------- | ---------------------------------------------- |
| `make setup-hooks`       | Configure Git hooks     | Git hooks activated                            |
| `make helm-lint`         | Validate chart syntax   | Lint results                                   |
| `make helm-build`        | Build and package chart | `scispace-openmeter-helm-{VERSION}.tgz`        |
| `make helm-build-latest` | Build with latest tag   | Version + `scispace-openmeter-helm-latest.tgz` |
| `make helm-push`         | Push to ECR             | Chart in ECR                                   |
| `make helm-push-latest`  | Push with latest tag    | Version + latest in ECR                        |

### Composite Commands

| Command                   | Description                   | Actions                                  |
| ------------------------- | ----------------------------- | ---------------------------------------- |
| `make helm-deploy`        | Build and push chart          | `helm-build` + `helm-push`               |
| `make helm-deploy-latest` | Build and push with latest    | `helm-build-latest` + `helm-push-latest` |
| `make setup-dev`          | Setup development environment | `setup-hooks` + `helm-deps`              |

## 🏷️ Versioning System

### Version Components

1. **`version` file**: Contains semantic version (e.g., `1.0.0-beta.213`)
2. **Tag Templates**: Define how versions are formatted
3. **Chart.yaml**: Automatically updated to match version file

### Tag Format

- **Version Tag**: `{VERSION}` → `1.0.0-beta.213`
- **Latest Tag**: `latest`
- **Chart Package**: `scispace-openmeter-helm-{TAG}.tgz`

### ECR Repository

Charts are pushed to: `249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm`

## 🪝 Git Hooks

### Pre-commit Hook Features

- ✅ **Version Validation**: Ensures version file is updated
- ✅ **Chart Validation**: Runs `helm lint` on chart
- ✅ **Version Consistency**: Validates Chart.yaml matches version file
- ✅ **Syntax Checking**: Validates YAML syntax

### Hook Setup

```bash
./setup-hooks.sh
```

## 🚀 Deployment Process

### Manual Deployment

```bash
# 1. Update version
echo "1.0.0-beta.214" > version

# 2. Build chart
make helm-build-latest

# 3. Push to ECR
make helm-push-latest
```

### Automated Deployment

```bash
# Single command deployment
make helm-deploy-latest
```

### Installing from ECR

```bash
# Install specific version
helm install openmeter oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm --version 1.0.0-beta.213

# Install latest
helm install openmeter oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm --version latest
```

## 🔧 Configuration

### AWS Configuration

```bash
# Set AWS profile
export AWS_PROFILE=your-profile-name

# Ensure ECR access
aws ecr get-login-password --region us-west-2
```

### Build Configuration

Edit these files to customize the build:

- `version`: Update semantic version
- `tag-templates/version-tag-template`: Customize version tag format
- `tag-templates/latest-tag-template`: Customize latest tag format
- `build.sh`: Modify build process
- `push_to_ecr.sh`: Update ECR settings

## 🔍 Troubleshooting

### Common Issues

| Issue                        | Cause                       | Solution                                    |
| ---------------------------- | --------------------------- | ------------------------------------------- |
| **Version validation fails** | Version file not updated    | Update `version` file before commit         |
| **Chart lint fails**         | Invalid Helm syntax         | Fix chart templates and run `helm lint`     |
| **ECR push fails**           | AWS credentials/permissions | Check AWS profile and ECR permissions       |
| **Build fails**              | Missing dependencies        | Run `make helm-deps` to update dependencies |

### Debug Commands

```bash
# Test chart syntax
make helm-lint

# Test chart with dry-run
make helm-test

# Check version consistency
cat version
grep '^version:' deploy/charts/openmeter/Chart.yaml

# Validate Git hooks
./hooks/pre-commit
```

## 📊 Build Artifacts

### Generated Files

- `deploy/charts/scispace-openmeter-helm-{VERSION}.tgz`: Version-specific chart
- `deploy/charts/scispace-openmeter-helm-latest.tgz`: Latest chart (with `--enable-latest`)

### ECR Artifacts

- `oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm:{VERSION}`
- `oci://249531194221.dkr.ecr.us-west-2.amazonaws.com/scispace/openmeter-helm:latest`

## 🔒 Security Considerations

- 🔐 AWS credentials stored securely
- 🛡️ ECR repository access controlled via IAM
- 📝 Git hooks prevent invalid commits
- 🔍 Chart validation before deployment
- 📊 Version tracking for audit trails

## 🎯 Best Practices

1. **Always update version file** before making changes
2. **Test locally** with `make helm-test` before committing
3. **Use semantic versioning** for version management
4. **Deploy with latest tag** for production releases
5. **Validate charts** with `make helm-lint` regularly
6. **Keep dependencies updated** with `make helm-deps`

## 🔄 CI/CD Integration

This build system can be integrated with CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Setup Development Environment
  run: make setup-dev

- name: Build and Deploy Chart
  run: make helm-deploy-latest
  env:
    AWS_PROFILE: ${{ secrets.AWS_PROFILE }}
```
