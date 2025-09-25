#!/bin/bash

PLAN_FILE=${1}

echo "⚠️ ================================================" >&2
echo "START: Ansible diff stage" >&2
EXIT_CODE=0

# load pipeline execution context from the file ansible_piepline.yml
source "$(dirname "$0")/ansible_piepline.sh"

echo "Ansible will be executed in the following context:"
# cat ${TERRATEAM_PLAN_FILE}

CTX_JSON=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' ${TERRATEAM_PLAN_FILE})
ANSIBLE_PLAYBOOK=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK')
ANSIBLE_PLAYBOOK_ERROR=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK_ERROR')

ANSIBLE_INVENTORY=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_INVENTORY')

ANSIBLE_CUSTOM_CFG=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_CUSTOM_CFG')

ANSIBLE_CUSTOM_REQUIREMENTS=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_CUSTOM_REQUIREMENTS')
ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE')
ANSIBLE_CUSTOM_REQUIREMENTS_ERROR=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_CUSTOM_REQUIREMENTS_ERROR')

ANSIBLE_PING_STDOUT=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PING.STDOUT')
ANSIBLE_PING_STDERR=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PING.STDERR')
ANSIBLE_PLAYBOOK_CHECK_STDOUT=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK_CHECK.STDOUT')
ANSIBLE_PLAYBOOK_CHECK_STDERR=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK_CHECK.STDERR')

TERRATEAM_ROOT=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ENV.TERRATEAM_ROOT')
TERRATEAM_DIR=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ENV.TERRATEAM_DIR')
TERRATEAM_WORKSPACE=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ENV.TERRATEAM_WORKSPACE')
ANSIBLE_ROOT=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.ENV.ANSIBLE_ROOT')

echo "Playbook: ${ANSIBLE_PLAYBOOK}"
echo "Playbook error: ${ANSIBLE_PLAYBOOK_ERROR}"

echo "Inventory: ${ANSIBLE_INVENTORY}"

echo "Custom cfg: ${ANSIBLE_CUSTOM_CFG}"

echo "Custom requirements: ${ANSIBLE_CUSTOM_REQUIREMENTS}"
echo "Custom requirements effective: ${ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE}"
echo "Custom requirements error: ${ANSIBLE_CUSTOM_REQUIREMENTS_ERROR}"

echo "Ping stdout: ${ANSIBLE_PING_STDOUT}"
echo "Ping stderr: ${ANSIBLE_PING_STDERR}"

echo "Playbook check stdout: ${ANSIBLE_PLAYBOOK_CHECK_STDOUT}"
echo "Playbook check stderr: ${ANSIBLE_PLAYBOOK_CHECK_STDERR}"

echo "Root: ${TERRATEAM_ROOT}"
echo "Dir: ${TERRATEAM_DIR}"
echo "Workspace: ${TERRATEAM_WORKSPACE}"
echo "Ansible root: ${ANSIBLE_ROOT}"



if [ "${DEBUG_DIFF}" == "true" ]; then
    echo 
    echo 
    echo "Environment variables (DEBUG):"
    echo "=============================="
    echo "CWD: ${PWD}"
    echo "TERRATEAM_DIR: ${TERRATEAM_DIR}"
    echo "TERRATEAM_WORKSPACE: ${TERRATEAM_WORKSPACE}"
    echo "TERRATEAM_ROOT: ${TERRATEAM_ROOT}"

    echo 
    echo 
    echo "Other tests (DEBUG):"
    echo "=============================="
    which ansible-galaxy
    which yq
    which jq

    echo "${CTX_JSON}" | jq
    echo "PLAYBOOK: ${ANSIBLE_PLAYBOOK}"
    echo "ROOT: ${TERRATEAM_ROOT}"
    echo "DIR: ${TERRATEAM_DIR}"
    echo "WORKSPACE: ${TERRATEAM_WORKSPACE}"
    echo "ANSIBLE_ROOT: ${ANSIBLE_ROOT}"
fi

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible diff stage" >&2
echo "⚠️ ================================================" >&2
exit ${EXIT_CODE}
