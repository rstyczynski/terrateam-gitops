#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible apply stage" >&2

echo 
echo "Environment variables (debug):" >&2
echo "======================" >&2
echo "CWD: $PWD" >&2
echo "TERRATEAM_DIR: $TERRATEAM_DIR" >&2
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE" >&2
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT" >&2


echo "Detect variables from plan file"

json=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' $TERRATEAM_PLAN_FILE)
PLAYBOOK=$(echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK')
echo "PLAYBOOK: $PLAYBOOK"
ANSIBLE_ROOT=$(echo "$json" | jq -r '.ansible_execution_context.ENV.ANSIBLE_ROOT')
echo "ANSIBLE_ROOT: $ANSIBLE_ROOT"

echo
echo "Running ansible-playbook"
cd $ANSIBLE_ROOT
ansible-playbook $PLAYBOOK


TERRATEAM_DEBUG=false
source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
