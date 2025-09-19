#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible plan stage" >&2


#
# initialize plan file
#
echo >> $PLAN_FILE
echo "Ansible plan" > $PLAN_FILE
echo "============" >> $PLAN_FILE

#
# detect workspace 
#
if [ "${TERRATEAM_WORKSPACE}" == "default" ]; then
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}
else
    ANSIBLE_ROOT=${TERRATEAM_ROOT}/${TERRATEAM_DIR}/${TERRATEAM_WORKSPACE}
fi
cd ${ANSIBLE_ROOT}

#
# detect ansible.cfg
#
test  -f "ansible.cfg" && ANSIBLE_CUSTOM_CFG=${ANSIBLE_ROOT}/ansible.cfg || unset ANSIBLE_CUSTOM_CFG
if [ ! -z  "${ANSIBLE_CUSTOM_CFG}" ]; then
    echo >> $PLAN_FILE
    echo "Custom ansible.cfg:" >> $PLAN_FILE
    echo "===================" >> $PLAN_FILE
    cat ${ANSIBLE_CUSTOM_CFG} >> $PLAN_FILE
else
    echo "Default ansible.cfg" >> $PLAN_FILE
fi

#
# install requirements
#
test  -f "requirements.yml" && ANSIBLE_CUSTOM_REQUIREMENTS=${ANSIBLE_ROOT}/requirements.yml || unset ANSIBLE_CUSTOM_REQUIREMENTS
if [ ! -z "${ANSIBLE_CUSTOM_REQUIREMENTS}" ]; then
    echo >> $PLAN_FILE
    echo "Requirements file:" >> $PLAN_FILE
    echo "==================" >> $PLAN_FILE
    cat ${ANSIBLE_CUSTOM_REQUIREMENTS} >> $PLAN_FILE
    echo "No requirements to install." >> $PLAN_FILE
fi



source "$(dirname "$0")/../shared/debug.sh" >&2

echo "TODO Ansible plan stdout message. 'TODO Ansible plan file content' is sent to $PLAN_FILE"

echo "TERRATEAM_PLAN_FILE (exported): $TERRATEAM_PLAN_FILE" >&2
echo "TERRATEAM_PLAN_FILE (argumnet): $PLAN_FILE" >&2
EXIT_CODE=0

echo "END: Ansible plan stage" >&2
echo "⚠️ ================================================" >&2

echo "⚠️ ================================================" >&2
echo ">>TERRATEAM_PLAN_FILE: $TERRATEAM_PLAN_FILE" >&2
cat $TERRATEAM_PLAN_FILE >&2
echo "<<TERRATEAM_PLAN_FILE" >&2
echo "⚠️ ================================================" >&2

exit $EXIT_CODE

