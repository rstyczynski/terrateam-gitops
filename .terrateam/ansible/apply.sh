#!/bin/bash

# Ansible engine apply stage script
# This script handles the apply stage for Ansible playbooks

echo "Running Ansible engine apply stage..."
echo "Applying Ansible playbook..."

# Run ansible-playbook
echo "Running Ansible playbook..."
ansible-playbook playbook.yml --diff

# Capture the exit code
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "Ansible playbook applied successfully!"
else
    echo "Ansible playbook application failed with exit code: $EXIT_CODE"
fi

echo "Apply stage completed!"
exit $EXIT_CODE
