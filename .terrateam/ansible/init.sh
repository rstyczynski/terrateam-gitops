#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible init stage" >&2

echo "TODO Ansible init"
if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "❌ Error: 'ansible-playbook' command not found. Please install Ansible before proceeding." >&2
else
    echo "ℹ️ ansible-playbook version info:" >&2
    ansible-playbook --version >&2

    if ! command -v ansible >/dev/null 2>&1; then
        echo "⚠️ Notice: 'ansible' command not found. Please install Ansible before proceeding." >&2
    else
        echo "ℹ️ ansible version info:" >&2
        ansible --version >&2
    fi
fi

EXIT_CODE=0

echo "⚠️ ================================================" >&2
echo "STOP: Ansible init stage" >&2
exit $EXIT_CODE