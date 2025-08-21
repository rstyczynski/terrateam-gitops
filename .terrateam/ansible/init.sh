#!/bin/bash

echo "⚠️ ================================================"
echo "START: Ansible init stage"

echo "TODO"
if ! command -v ansible >/dev/null 2>&1; then
  echo "❌ Error: 'ansible' command not found. Please install Ansible before proceeding."
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "❌ Error: 'ansible-playbook' command not found. Please install Ansible before proceeding."
fi

EXIT_CODE=0

echo "⚠️ ================================================"
echo "STOP: Ansible apply stage"
exit $EXIT_CODE