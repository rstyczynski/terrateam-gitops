#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible apply stage" >&2

# load pipeline execution context from the file ansible_piepline.yml
source "$(dirname "$0")/ansible_piepline.sh"

# load variables from plan file
json=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' $TERRATEAM_PLAN_FILE)
ANSIBLE_ROOT=$(echo "$json" | jq -r '.ansible_execution_context.ENV.ANSIBLE_ROOT')
PLAYBOOK=$(echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK')
echo "$json" | jq -r '.ansible_execution_context.ANSIBLE_INVENTORY' > inventory_static.yml

if [ "${DEBUG_APPLY}" == "true" ]; then
  echo 
  echo "Environment variables (debug):" >&2
  echo "======================" >&2
  echo "CWD: $PWD" >&2
  echo "TERRATEAM_DIR: $TERRATEAM_DIR" >&2
  echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE" >&2
  echo "TERRATEAM_ROOT: $TERRATEAM_ROOT" >&2

  echo "Plan file:"
  echo "=========="
  cat $TERRATEAM_PLAN_FILE
  echo

  echo "Detect variables from plan file"
  echo "==============================="
  echo "ANSIBLE_ROOT: $ANSIBLE_ROOT"
  echo "PLAYBOOK: $PLAYBOOK"
  echo "INVENTORY: $(cat inventory_static.yml)"

fi


echo
echo "✅ Running ansible-playbook"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd $ANSIBLE_ROOT

if [ "$(cat inventory_static.yml)" != "" ]; then
  ansible-playbook $PLAYBOOK -i inventory_static.yml 2> >(tee /tmp/ansible_stderr.log >&2)
else
  rm inventory_static.yml
  ansible-playbook $PLAYBOOK  2> >(tee /tmp/ansible_stderr.log >&2)
fi

if [[ -s /tmp/ansible_stderr.log ]]; then
    echo "⚠️ warnings & errors"
    cat /tmp/ansible_stderr.log
fi

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
