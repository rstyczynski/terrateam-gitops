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
ANSIBLE_ROOT=$(echo "$json" | jq -r '.ansible_execution_context.ENV.ANSIBLE_ROOT')
echo "ANSIBLE_ROOT: $ANSIBLE_ROOT"
PLAYBOOK=$(echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK')
echo "PLAYBOOK: $PLAYBOOK"
echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_INVENTORY' > inventory_static.yml
echo "INVENTORY: $(cat inventory_static.yml)"

echo
echo "Running ansible-playbook"
cd $ANSIBLE_ROOT
ansible-playbook $PLAYBOOK -i inventory_static.yml


TERRATEAM_DEBUG=false
source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
