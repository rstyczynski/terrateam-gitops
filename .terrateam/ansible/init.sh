#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible init stage" >&2

echo "Ansible init"

#
# detect workspace 
#
if [ "${TERRATEAM_WORKSPACE}" == "default" ]; then
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}
else
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}/${TERRATEAM_WORKSPACE}
fi
cd $ANSIBLE_ROOT

#
# detest ansible.cfg
#
if [ -f "ansible.cfg" ]; then
    echo "Ansible cfg file found"
    cat ansible.cfg
else
    echo "Using default ansible configuration.ansible.cfg file not found in workspace directory."
fi

#
# install requirements
#
if [ -f "requirements.yml" ]; then
    echo "Requirements file found"
    ansible-galaxy install -r requirements.yml
else
    echo "No requirements to install. Requirements file not found in workspace directory."
fi



EXIT_CODE=0

source "$(dirname "$0")/../shared/debug.sh" >&2
echo "⚠️ ================================================" >&2
echo "STOP: Ansible init stage" >&2
exit $EXIT_CODE