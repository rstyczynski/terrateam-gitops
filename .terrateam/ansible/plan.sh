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

#
# detect playbook to run
# Rules:
# 1. If there is only one playbook.yml file, use it.
# 2. If there are multiple playbook.yml files, use the one specified in ANSIBLE_PLAYBOOK file.
# 3. If there are no playbook.yml files, error out.
#
# ANSIBLE_PLAYBOOK file content is a single line with the name of the playbook to run.
#
# If ANSIBLE_PLAYBOOK file is not present, error out.

# List all .yml files in the directory (excluding requirements.yml and ansible.cfg)
playbooks=($(ls *.yml 2>/dev/null | grep -v -E '^(requirements|ansible)\.yml$'))

if [ ${#playbooks[@]} -eq 1 ]; then
    ANSIBLE_PLAYBOOK="${playbooks[0]}"
elif [ ${#playbooks[@]} -gt 1 ]; then
    if [ -f "ANSIBLE_PLAYBOOK" ]; then
        ANSIBLE_PLAYBOOK=$(cat ANSIBLE_PLAYBOOK | tr -d '[:space:]')
        if [ ! -f "$ANSIBLE_PLAYBOOK" ]; then
            echo "ERROR: Playbook file specified in ANSIBLE_PLAYBOOK ('$ANSIBLE_PLAYBOOK') does not exist." >&2
            exit 1
        fi
    else
        echo "ERROR: Multiple playbook .yml files found, but no ANSIBLE_PLAYBOOK file present." >&2
        exit 1
    fi
else
    echo "ERROR: No playbook .yml files found in directory." >&2
    exit 1
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

