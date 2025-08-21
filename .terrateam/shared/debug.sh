#!/bin/bash

# Debug script for Ansible engine diagnostics

echo "🔍 START: Diagnostic dump ================================"

echo "========== TERRATEAM ENVIRONMENT VARIABLES =========="
echo "TERRATEAM_DIR: $TERRATEAM_DIR"
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE"
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT"

echo "TERRATEAM_PLAN_FILE: $TERRATEAM_PLAN_FILE"
echo ">>>>"
cat $TERRATEAM_PLAN_FILE
echo "<<<<"

echo "TERRATEAM_RESULTS_FILE: $TERRATEAM_RESULTS_FILE"
echo ">>>>"
cat $TERRATEAM_RESULTS_FILE
echo "<<<<"

echo "========== ENVIRONMENT VARIABLES =========="
env

echo "========== SHELL =========="
echo "SHELL: $SHELL"
echo "BASH_VERSION: $BASH_VERSION"

echo "========== USER =========="
echo "USER: $USER"
echo "HOME: $HOME"
echo "PWD: $PWD"

echo "========== PATH =========="
echo "$PATH" | tr ':' '\n'

echo "========== PIP INFO =========="
if command -v pip >/dev/null 2>&1; then
    pip --version
    pip config list
else
    echo "❌ pip not found"
fi

echo "========== PYTHON INFO =========="
if command -v python >/dev/null 2>&1; then
    python --version
    python -m site
else
    echo "❌ python not found"
fi

echo "========== PIP CACHE =========="
echo "PIP cache dir: ${PIP_CACHE_DIR:-$HOME/.cache/pip}" 

echo "========== PIP .cache CHECK =========="
ls -ld "$HOME" "$HOME/.cache" "$HOME/.cache/pip" 2>/dev/null || echo "Cache dir missing" 
namei -l "$HOME/.cache/pip" 2>/dev/null || echo "namei not available" 
stat -c "%U:%G %A %n" "$HOME/.cache/pip" 2>/dev/null || echo "stat failed" 
touch "$HOME/.cache/pip/testfile" 2>/dev/null && echo "Writable"  || echo "Not writable" 
rm -f "$HOME/.cache/pip/testfile" 2>/dev/null


echo "========== ANSIBLE INFO =========="
if command -v ansible-playbook >/dev/null 2>&1; then
    echo "🛠️ ansible-playbook version:"
    ansible-playbook --version
else
    echo "❌ ansible-playbook not found"
fi
if command -v ansible >/dev/null 2>&1; then
    echo "🛠️ ansible version:"
    ansible --version
else
    echo "❌ ansible not found"
fi

echo "🔍 END: Diagnostic dump ================================"
