#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible plan stage" >&2


#
# initialize plan file
#
if [ "${PLAN_DEBUG}" == "true" ]; then
    echo >> $PLAN_FILE
    echo "Ansible plan (DEBUG)" > $PLAN_FILE
    echo "===================" >> $PLAN_FILE
fi

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

if [ "${PLAN_DEBUG}" == "true" ]; then
    if [ ! -z  "${ANSIBLE_CUSTOM_CFG}" ]; then
        echo >> $PLAN_FILE
        echo "Custom ansible.cfg (DEBUG):" >> $PLAN_FILE
        echo "===========================" >> $PLAN_FILE
        cat ${ANSIBLE_CUSTOM_CFG} >> $PLAN_FILE
    else
        echo "Default ansible.cfg" >> $PLAN_FILE
    fi
fi

#
# install requirements
#
test  -f "requirements.yml" && ANSIBLE_CUSTOM_REQUIREMENTS=${ANSIBLE_ROOT}/requirements.yml || unset ANSIBLE_CUSTOM_REQUIREMENTS

if [ "${PLAN_DEBUG}" == "true" ]; then
    if [ ! -z "${ANSIBLE_CUSTOM_REQUIREMENTS}" ]; then
        echo >> $PLAN_FILE
        echo "Requirements file (DEBUG):" >> $PLAN_FILE
        echo "==========================" >> $PLAN_FILE
        cat ${ANSIBLE_CUSTOM_REQUIREMENTS} >> $PLAN_FILE
    else
        echo "No requirements to install." >> $PLAN_FILE
    fi
fi

#
# list collections
#
if [ "${PLAN_DEBUG}" == "true" ]; then
    ansible-galaxy collection list >> $PLAN_FILE
fi

ANSIBLE_GALAXY_COLLECTIONS=$(ansible-galaxy collection list)


#
# detect playbook to run
# Rules:
# 1. If there is ANSIBLE_PLAYBOOK file, use the one specified in it.
# 2. If there is only one playbook.yml file, use it.
# 4. If there are multiple playbook.yml files, use the one specified in ANSIBLE_PLAYBOOK file.
# 5. If detected playbook file does not exist, error out.
#
# ANSIBLE_PLAYBOOK file content is a single line with the name of the playbook to run.
# ANSIBLE_PLAYBOOK file may be missing.

# Detect playbook to run

# Default to empty
ANSIBLE_PLAYBOOK=""

# 1. If there is ANSIBLE_PLAYBOOK file, use the one specified in it.
if [ -f "ANSIBLE_PLAYBOOK" ]; then
    PLAYBOOK_FILE=$(head -n 1 ANSIBLE_PLAYBOOK | xargs)
    if [ -z "$PLAYBOOK_FILE" ]; then
        echo "ERROR: ANSIBLE_PLAYBOOK file is empty." >&2
        exit 1
    fi
    if [ ! -f "$PLAYBOOK_FILE" ]; then
        echo "ERROR: Playbook specified in ANSIBLE_PLAYBOOK ('$PLAYBOOK_FILE') does not exist." >&2
        exit 1
    fi
    ANSIBLE_PLAYBOOK="$PLAYBOOK_FILE"
else
    # 2. If there is only one playbook.yml file, use it.
    # 4. If there are multiple playbook.yml files, use the one specified in ANSIBLE_PLAYBOOK file.
    # (Rule 3 is missing, so we skip to 4)
    PLAYBOOKS_FOUND=($(find . -maxdepth 1 -type f -name "playbook.yml"))
    if [ ${#PLAYBOOKS_FOUND[@]} -eq 1 ]; then
        ANSIBLE_PLAYBOOK="${PLAYBOOKS_FOUND[0]#./}"
    elif [ ${#PLAYBOOKS_FOUND[@]} -gt 1 ]; then
        ANSIBLE_PLAYBOOK_ERROR="Multiple playbook.yml files found. Please specify which to use in ANSIBLE_PLAYBOOK file."
    else
        ANSIBLE_PLAYBOOK_ERROR="ERROR: No playbook.yml file found and no ANSIBLE_PLAYBOOK file present."
    fi
fi

# 5. If detected playbook file does not exist, error out.
if [ ! -f "$ANSIBLE_PLAYBOOK" ]; then
    ANSIBLE_PLAYBOOK_ERROR="ERROR: Detected playbook file '$ANSIBLE_PLAYBOOK' does not exist."
fi

if [ "${PLAN_DEBUG}" == "true" ]; then
    echo >> $PLAN_FILE
    echo "Using playbook (DEBUG):" >> $PLAN_FILE
    echo "=======================" >> $PLAN_FILE
    if [ ! -z "$ANSIBLE_PLAYBOOK_ERROR" ]; then
        echo $ANSIBLE_PLAYBOOK_ERROR >> $PLAN_FILE
    else
        echo $ANSIBLE_PLAYBOOK >> $PLAN_FILE
    fi
fi



#
# write all variables to plan file in yml format
# 1. ANSIBLE_PLAYBOOK
# 2. ANSIBLE_PLAYBOOK_ERROR
# 3. ANSIBLE_CUSTOM_CFG
# 4. ANSIBLE_CUSTOM_REQUIREMENTS


# Write all relevant variables to the plan file in YAML format
{
    echo "---"
    echo "ansible_execution_context:"
    echo "  ANSIBLE_PLAYBOOK: \"${ANSIBLE_PLAYBOOK}\""
    echo "  "
    echo "  ANSIBLE_PLAYBOOK_ERROR: \"${ANSIBLE_PLAYBOOK_ERROR}\""
    echo "  "
    # If ANSIBLE_CUSTOM_CFG is a file and exists, encode as YAML block scalar
    if [ -n "$ANSIBLE_CUSTOM_CFG" ] && [ -f "$ANSIBLE_CUSTOM_CFG" ]; then
        echo "  ANSIBLE_CUSTOM_CFG: |"
        sed 's/^/    /' "$ANSIBLE_CUSTOM_CFG"
    else
        echo "  ANSIBLE_CUSTOM_CFG: \"${ANSIBLE_CUSTOM_CFG}\""
    fi
    echo "  "

    # If ANSIBLE_CUSTOM_REQUIREMENTS is a file and exists, encode as YAML block scalar
    if [ -n "$ANSIBLE_CUSTOM_REQUIREMENTS" ] && [ -f "$ANSIBLE_CUSTOM_REQUIREMENTS" ]; then
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS: |"
        sed 's/^/    /' "$ANSIBLE_CUSTOM_REQUIREMENTS"
    else
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS: \"${ANSIBLE_CUSTOM_REQUIREMENTS}\""
    fi
    echo "  "

    echo "  ANSIBLE_GALAXY_COLLECTIONS: |"
    sed 's/^/    /' "$ANSIBLE_GALAXY_COLLECTIONS"
    echo "  "

    # Add TERRATEAM_DIR, TERRATEAM_WORKSPACE, and TERRATEAM_ROOT
    echo "  ENV:"
    env | grep -E '^(TERRATEAM_DIR|TERRATEAM_WORKSPACE|TERRATEAM_ROOT)=' | sed 's/^\(.*\)=\(.*\)$/    \1: "\2"/'
} >> $PLAN_FILE

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

