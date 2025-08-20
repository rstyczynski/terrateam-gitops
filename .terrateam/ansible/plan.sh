#!/bin/bash

# Ansible engine plan stage script
# This script handles the planning stage for Ansible playbooks

echo "Running Ansible engine plan stage..."
echo "Creating Ansible execution plan..."

# Change to the ansible directory
cd ../ansible

# Get the plan file path from the first argument
PLAN_FILE="$1"

# Run ansible-playbook in check mode (dry run)
echo "Running Ansible playbook in check mode..."
ansible-playbook playbook.yml --check --diff

# Capture the exit code
EXIT_CODE=$?

# Create a plan summary
cat > "$PLAN_FILE" <<EOF
# Ansible Playbook Plan

## Playbook: playbook.yml
## Check Mode: Enabled
## Diff Mode: Enabled

## Tasks to be executed:
1. Display hello message
2. Display environment info
3. Create a test file (conditional)
4. Show summary

## Variables from vars.json:
$(cat vars.json | python3 -m json.tool)

## Plan Status: $(if [ $EXIT_CODE -eq 0 ]; then echo "SUCCESS"; else echo "FAILED"; fi)

## Exit Code: $EXIT_CODE
EOF

echo "Plan stage completed successfully!"
exit $EXIT_CODE
