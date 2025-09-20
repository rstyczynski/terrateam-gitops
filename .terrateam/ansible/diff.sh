#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible diff stage" >&2

echo "Ansible will be executed in the following context:"
cat $TERRATEAM_PLAN_FILE
EXIT_CODE=0


TERRATEAM_DEBUG=false
if [ "${TERRATEAM_DEBUG}" == "true" ]; then
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
    echo "ANSIBLE_ROOT: $ANSIBLE_ROOT"

fi

echo "END: Ansible diff stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
