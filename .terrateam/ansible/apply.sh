#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible apply stage" >&2

echo "Ansible apply"

echo 
echo "Environment variables (debug):"
echo "======================"
echo "CWD: $PWD"
echo "TERRATEAM_DIR: $TERRATEAM_DIR"
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE"
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT"
EXIT_CODE=0

echo "Detect variables from plan file"

json=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' $TERRATEAM_PLAN_FILE)
echo "$json" | jq

PLAYBOOK=$(echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK')
echo "PLAYBOOK: $PLAYBOOK"
ROOT=$(echo "$json" | jq -r '.ansible_execution_context.ENV.TERRATEAM_ROOT')
echo "ROOT: $ROOT"
DIR=$(echo "$json" | jq -r '.ansible_execution_context.ENV.TERRATEAM_DIR')
echo "DIR: $DIR"
WORKSPACE=$(echo "$json" | jq -r '.ansible_execution_context.ENV.TERRATEAM_WORKSPACE')
echo "WORKSPACE: $WORKSPACE"
ANSIBLE_ROOT=$(echo "$json" | jq -r '.ansible_execution_context.ENV.ANSIBLE_ROOT')
echo "WORKSPACE: $ANSIBLE_ROOT"

echo "Running ansible-playbook"
cd $ANSIBLE_ROOT
ansible-playbook $PLAYBOOK


TERRATEAM_DEBUG=false
source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
