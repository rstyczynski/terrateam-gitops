#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible init stage" >&2

echo "TODO Ansible init"

{
    echo "Diagnostic dump"

    # 1. Who am I?
    whoami
    id

    # 2. What does pip think my home is?
    echo "HOME=$HOME"

    # 3. Inspect the pip cache path
    echo "PIP cache dir: ${PIP_CACHE_DIR:-$HOME/.cache/pip}"

    # 4. Check if it exists
    ls -ld "$HOME" "$HOME/.cache" "$HOME/.cache/pip" 2>/dev/null || echo "Cache dir missing"

    # 5. Show ownership & permissions (drill down a bit)
    namei -l "$HOME/.cache/pip" 2>/dev/null || echo "namei not available"
    stat -c "%U:%G %A %n" "$HOME/.cache/pip" 2>/dev/null || echo "stat failed"

    # 6. Try creating a file (tests writability)
    touch "$HOME/.cache/pip/testfile" 2>/dev/null && echo "Writable" || echo "Not writable"
    rm -f "$HOME/.cache/pip/testfile" 2>/dev/null
} >&2

# removes error message from log, but does not improve 
# the speed as each stage runs in a separate container
mkdir -p ~/.cache

# first use of ansible-playbook command initiates 
# pip install of ansible and its dependencies
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