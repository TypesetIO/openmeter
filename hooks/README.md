# Git Hooks

This directory contains Git hooks for the OpenMeter repository.

## Setup

Run the setup script to configure Git hooks:

```bash
./setup-hooks.sh
```

## Hooks

### pre-commit

The pre-commit hook performs the following checks:

1. **Version Validation**: Ensures the version file has been updated for new commits
2. **Helm Chart Validation**: Runs `helm lint` to validate chart syntax
3. **Version Consistency**: Ensures Chart.yaml version matches the version file

### Features

- Skips version check for the first commit
- Validates Helm chart syntax before allowing commits
- Ensures version consistency across files
- Provides clear error messages for failed validations
