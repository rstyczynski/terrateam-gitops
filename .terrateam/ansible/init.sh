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
cd ${ANSIBLE_ROOT}


echo "Hello World by Ansible init no.4!" > ${ANSIBLE_ROOT}/../terraform/hello.txt
export COMMIT_MSG="Hello! file updated"
${TERRATEAM_ROOT}/${TERRATEAM_DIR}.terrateam/shared/commit.sh


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
    ansible-galaxy install -r ${ANSIBLE_CUSTOM_REQUIREMENTS}
else
    echo "No requirements to install. Requirements file not found in workspace directory."
fi



EXIT_CODE=0

TERRATEAM_DEBUG=false
source "$(dirname "$0")/../shared/debug.sh" >&2
echo "⚠️ ================================================" >&2
echo "STOP: Ansible init stage" >&2
exit $EXIT_CODE