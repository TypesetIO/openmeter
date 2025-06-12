#!/bin/bash

# Set the hooks directory to our project's hooks directory
git config core.hooksPath hooks

echo "Git hooks have been configured successfully!"
echo "Pre-commit hook is now active and will check for version changes and validate Helm charts." 