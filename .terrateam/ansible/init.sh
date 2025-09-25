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
PWD
ls -la

#
# install ansible. Terrateam checks if ansible is installed 
# and if not, it installs it when ansible-playbook is executed.
#
ansible-playbook --version

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