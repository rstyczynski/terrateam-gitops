#!/bin/bash

# Ansible engine init stage script
# This script handles the initialization stage for Ansible playbooks

echo "Running Ansible engine init stage..."
echo "Initializing Ansible configuration..."

# Change to the ansible directory
cd ../ansible

# Check if ansible is available
if ! command -v ansible &> /dev/null; then
    echo "Error: Ansible is not installed or not in PATH"
    exit 1
fi

# Validate the playbook and vars file
if [ ! -f "playbook.yml" ]; then
    echo "Error: playbook.yml not found"
    exit 1
fi

if [ ! -f "vars.json" ]; then
    echo "Error: vars.json not found"
    exit 1
fi

# Validate JSON syntax
if ! python3 -m json.tool vars.json > /dev/null 2>&1; then
    echo "Error: vars.json contains invalid JSON"
    exit 1
fi

echo "Ansible configuration validated successfully!"
echo "Init stage completed successfully!"
