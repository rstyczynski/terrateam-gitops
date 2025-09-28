#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible init stage" >&2

# load pipeline execution context from the file ansible_piepline.yml
source "$(dirname "$0")/ansible_piepline.sh"

echo "Ansible init"

#
# detect workspace 
#
if [ "${TERRATEAM_WORKSPACE}" == "default" ]; then
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}
else
    # Note: the workspace does not influence working directory
    # ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}/${TERRATEAM_WORKSPACE}
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}
fi
cd ${ANSIBLE_ROOT} | exit 2
pwd
ls -la

#
# install ansible. Terrateam checks if ansible is installed 
# and if not, it installs it when ansible-playbook is executed.
#
ansible-playbook --version


#
# execute init script
#
CTX_JSON=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' ${TERRATEAM_PLAN_FILE})
INIT_SCRIPT=$(echo "${CTX_JSON}" | jq -r '.ansible_execution_context.control.init_script // empty')
if [ -n "${INIT_SCRIPT}" ]; then
    echo "Executing init script from pipeline context..."
    eval "${INIT_SCRIPT}"
    INIT_EXIT_CODE=$?
    if [ $INIT_EXIT_CODE -ne 0 ]; then
        echo "Error: Init script failed with exit code $INIT_EXIT_CODE" >&2
        exit $INIT_EXIT_CODE
    fi
else
    echo "No init script found in pipeline context."
fi

#
# detect ansible.cfg
#
test  -f "ansible.cfg" && ANSIBLE_CUSTOM_CFG=${ANSIBLE_ROOT}/ansible.cfg || unset ANSIBLE_CUSTOM_CFG
if [ ! -z  "${ANSIBLE_CUSTOM_CFG}" ]; then
    echo "Ansible cfg file found."
    cat ${ANSIBLE_CUSTOM_CFG}
else
    echo "Using default ansible configuration.ansible.cfg file not found in workspace directory."
fi

#
# install requirements
#
test  -f "requirements.yml" && ANSIBLE_CUSTOM_REQUIREMENTS=${ANSIBLE_ROOT}/requirements.yml || unset ANSIBLE_CUSTOM_REQUIREMENTS
if [ ! -z "${ANSIBLE_CUSTOM_REQUIREMENTS}" ]; then
    echo "Requirements file found."
    cat ${ANSIBLE_CUSTOM_REQUIREMENTS}

    # apply firewall to requirements.yml to remove public sources
    $(dirname "$0")/galaxy_firewall.py ${ANSIBLE_CUSTOM_REQUIREMENTS} > requirements_firewall.yml
    firewall_exit_code=$?
    if [ $firewall_exit_code -eq 0 ]; then
        :
    elif [ $firewall_exit_code -eq 1 ]; then
        echo "Error: requirements file does not exist, but firewall executed."
    elif [ $firewall_exit_code -eq 2 ]; then
        echo "Warning: Requirements file uses public sources. Public sources removed."
    else
        echo "Error: galaxy_firewall.py failed with exit code $firewall_exit_code" >&2
        exit 2
    fi

    # install requirements
    ansible-galaxy install -r requirements_firewall.yml
else
    echo "Info. No requirements to install. Requirements file not found in workspace directory."
fi

EXIT_CODE=0


source "$(dirname "$0")/../shared/debug.sh" >&2
echo "⚠️ ================================================" >&2
echo "STOP: Ansible init stage" >&2
exit $EXIT_CODE