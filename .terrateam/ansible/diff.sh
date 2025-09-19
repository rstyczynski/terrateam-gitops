#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible diff stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "Ansible will be executed in the following context:"
cat $TERRATEAM_PLAN_FILE


echo 
echo 
echo "Environment variables (DEBUG):"
echo "=============================="
echo "CWD: $PWD"
echo "TERRATEAM_DIR: $TERRATEAM_DIR"
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE"
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT"

echo 
echo 
echo "Other tests (DEBUG):"
echo "=============================="
which ansible-galaxy
which yq
which jq


EXIT_CODE=0

echo "END: Ansible diff stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
