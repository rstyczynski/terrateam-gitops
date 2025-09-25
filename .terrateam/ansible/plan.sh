#!/bin/bash

PLAN_FILE=${1}

function plan_debug() {
    local DEBUG_MSG=${1}

    if [ -f "${DEBUG_MSG}" ]; then
        cat "${DEBUG_MSG}" | sed 's/^/# /' >> ${PLAN_FILE}
    else
        echo "# ${DEBUG_MSG}" >> ${PLAN_FILE}
    fi
}

echo "⚠️ ================================================" >&2
echo "START: Ansible plan stage" >&2

# load pipeline execution context from the file ansible_piepline.yml
source "$(dirname "$0")/ansible_piepline.sh"

touch ${PLAN_FILE}
rm -f ${PLAN_FILE}


#
# initialize plan file
#
if [ "${DEBUG_PLAN}" == "true" ]; then
    plan_debug "Ansible plan (DEBUG)"
    plan_debug "==================="
fi

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
# detect ansible.cfg
#
test  -f "ansible.cfg" && ANSIBLE_CUSTOM_CFG=${ANSIBLE_ROOT}/ansible.cfg || unset ANSIBLE_CUSTOM_CFG

if [ "${DEBUG_PLAN}" == "true" ]; then
    if [ ! -z  "${ANSIBLE_CUSTOM_CFG}" ]; then
        plan_debug
        plan_debug "Custom ansible.cfg (DEBUG):" 
        plan_debug "==========================="
        plan_debug "${ANSIBLE_CUSTOM_CFG}"
    else
        plan_debug "Default ansible.cfg"
    fi
fi

#
# install requirements
#
test  -f "requirements.yml" && ANSIBLE_CUSTOM_REQUIREMENTS=${ANSIBLE_ROOT}/requirements.yml || unset ANSIBLE_CUSTOM_REQUIREMENTS

test  -f "requirements_firewall.yml" && ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE=${ANSIBLE_ROOT}/requirements_firewall.yml || unset ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE

if [ -f "${ANSIBLE_CUSTOM_REQUIREMENTS}" ]; then
    $(dirname "$0")/galaxy_firewall.py ${ANSIBLE_CUSTOM_REQUIREMENTS} > /dev/null
    FIREWALL_EXIT_CODE=$?
    if [ ${FIREWALL_EXIT_CODE} -eq 0 ]; then
        unset ANSIBLE_CUSTOM_REQUIREMENTS_ERROR
    elif [ ${FIREWALL_EXIT_CODE} -eq 1 ]; then
        ANSIBLE_CUSTOM_REQUIREMENTS_ERROR="Error: requirements file does not exist, but firewall executed."
    elif [ ${FIREWALL_EXIT_CODE} -eq 2 ]; then
        ANSIBLE_CUSTOM_REQUIREMENTS_ERROR="Warning: Requirements file uses public sources. Public sources removed."
    else
        ANSIBLE_CUSTOM_REQUIREMENTS_ERROR="Error: galaxy_firewall.py failed with exit code ${FIREWALL_EXIT_CODE}" >&2
    fi
fi

if [ "${DEBUG_PLAN}" == "true" ]; then
    if [ ! -z "${ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE}" ]; then
        plan_debug
        plan_debug "Requirements file (DEBUG):"
        plan_debug "=========================="
        plan_debug "${ANSIBLE_CUSTOM_REQUIREMENTS}"

        plan_debug
        plan_debug "Requirements file effective (DEBUG):"
        plan_debug "=========================="
        plan_debug "${ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE}"

    else
        plan_debug "No requirements to install."
    fi
fi

#
# list collections
#
if [ "${DEBUG_PLAN}" == "true" ]; then

    ansible-galaxy collection list > /tmp/ansible_galaxy_collections.txt 2>&1
    plan_debug "Collections list (DEBUG):"
    plan_debug "=========================="
    plan_debug /tmp/ansible_galaxy_collections.txt
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
    if [ -z "${PLAYBOOK_FILE}" ]; then
        echo "ERROR: ANSIBLE_PLAYBOOK file is empty." >&2
        exit 1
    fi
    if [ ! -f "${PLAYBOOK_FILE}" ]; then
        echo "ERROR: Playbook specified in ANSIBLE_PLAYBOOK ('${PLAYBOOK_FILE}') does not exist." >&2
        exit 1
    fi
    ANSIBLE_PLAYBOOK="${PLAYBOOK_FILE}"
else
    # 2. If there is only one *.yml file (excluding requirements.yml and requirements_firewall.yml), use it.
    # 4. If there are multiple *.yml files, use the one specified in ANSIBLE_PLAYBOOK file.
    PLAYBOOKS_FOUND=($(find . -maxdepth 1 -type f -name "*.yml" ! -name "requirements.yml" ! -name "requirements_firewall.yml" ! -name "ansible_piepline.yml"))
    if [ ${#PLAYBOOKS_FOUND[@]} -eq 1 ]; then
        ANSIBLE_PLAYBOOK="${PLAYBOOKS_FOUND[0]#./}"
    elif [ ${#PLAYBOOKS_FOUND[@]} -gt 1 ]; then
        ANSIBLE_PLAYBOOK_ERROR="Multiple playbook.yml files found. Please specify which to use in ANSIBLE_PLAYBOOK file."
    else
        ANSIBLE_PLAYBOOK_ERROR="ERROR: No playbook.yml file found and no ANSIBLE_PLAYBOOK file present."
    fi
fi

# 5. If detected playbook file does not exist, error out.
if [ ! -f "${ANSIBLE_PLAYBOOK}" ]; then
    ANSIBLE_PLAYBOOK_ERROR="ERROR: Detected playbook file '${ANSIBLE_PLAYBOOK}' does not exist."
fi

if [ "${DEBUG_PLAN}" == "true" ]; then
    plan_debug
    plan_debug "Using playbook (DEBUG):"
    plan_debug "======================="
    if [ ! -z "${ANSIBLE_PLAYBOOK_ERROR}" ]; then
        plan_debug "${ANSIBLE_PLAYBOOK_ERROR}"
    else
        plan_debug "${ANSIBLE_PLAYBOOK}"
    fi
fi

#
# detect inventory
#
if [ -f "${ANSIBLE_ROOT}/inventory.ini" ]; then
    ansible-inventory -i inventory.ini  --list --export --yaml --output inventory_static.yml
    ANSIBLE_INVENTORY=inventory_static.yml
elif [ -f "${ANSIBLE_ROOT}/inventory.yml" ]; then
    ansible-inventory -i inventory.yml  --list --export --yaml --output inventory_static.yml
    ANSIBLE_INVENTORY=inventory_static.yml
else
    unset ANSIBLE_INVENTORY
fi

if [ "${DEBUG_PLAN}" == "true" ]; then
    plan_debug
    plan_debug "Using inventory (DEBUG):"
    plan_debug "=======================" 
    if [ ! -z "${ANSIBLE_INVENTORY}" ]; then
        plan_debug "${ANSIBLE_INVENTORY}" 
    else
        plan_debug "(none)"
    fi
fi

#
# write all variables to plan file in yml format
# 1. ANSIBLE_PLAYBOOK
# 2. ANSIBLE_PLAYBOOK_ERROR
# 3. ANSIBLE_CUSTOM_CFG
# 4. ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE

# Write all relevant variables to the plan file in YAML format
{
    echo "---"
    echo "ansible_execution_context:"
    echo "  ANSIBLE_PLAYBOOK: \"${ANSIBLE_PLAYBOOK}\""
    echo "  "
    echo "  ANSIBLE_PLAYBOOK_ERROR: \"${ANSIBLE_PLAYBOOK_ERROR}\""
    echo "  "


    if [ -f "${ANSIBLE_INVENTORY}" ]; then
        echo "  ANSIBLE_INVENTORY: |"
        sed 's/^/    /' "${ANSIBLE_INVENTORY}"
    else
        echo "  ANSIBLE_INVENTORY:"
    fi
    echo "  "

    # If ANSIBLE_CUSTOM_CFG is a file and exists, encode as YAML block scalar
    if [ -f "${ANSIBLE_CUSTOM_CFG}" ]; then
        echo "  ANSIBLE_CUSTOM_CFG: |"
        sed 's/^/    /' "${ANSIBLE_CUSTOM_CFG}"
    else
        echo "  ANSIBLE_CUSTOM_CFG:"
    fi
    echo "  "

    if [ -f "${ANSIBLE_CUSTOM_REQUIREMENTS}" ]; then
        echo
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS: |"
        sed 's/^/    /' "${ANSIBLE_CUSTOM_REQUIREMENTS}"
        echo "  "
    else
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS:"
    fi
    echo "  "

    # If ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE is a file and exists, encode as YAML block scalar
    if [ -f "${ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE}" ]; then
        echo
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE: |"
        sed 's/^/    /' "${ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE}"
        echo "  "
    else
        echo "  ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE:"
    fi
    echo "  "
    echo "  ANSIBLE_CUSTOM_REQUIREMENTS_ERROR: \"${ANSIBLE_CUSTOM_REQUIREMENTS_ERROR}\""
    echo "  "

    # Add TERRATEAM_DIR, TERRATEAM_WORKSPACE, and TERRATEAM_ROOT
    echo "  ENV:"
    echo "    ANSIBLE_ROOT: \"${ANSIBLE_ROOT}\""
    echo "    TERRATEAM_DIR: \"${TERRATEAM_DIR}\""
    echo "    TERRATEAM_WORKSPACE: \"${TERRATEAM_WORKSPACE}\""
    echo "    TERRATEAM_ROOT: \"${TERRATEAM_ROOT}\""
} >> ${PLAN_FILE}

#
# run ping
#
if [ "${SKIP_PING}" != "true" ]; then
    {
        echo
        echo "  ANSIBLE_PING:"
        cd ${ANSIBLE_ROOT}

        # Run ansible ping, capture stdout and stderr
        if [ "$(cat inventory_static.yml)" != "" ]; then
            ansible all -m ping -i inventory_static.yml > /tmp/ansible_ping_stdout.log 2> /tmp/ansible_ping_stderr.log
        else
            rm inventory_static.yml
            ansible all -m ping -i localhost, > /tmp/ansible_ping_stdout.log 2> /tmp/ansible_ping_stderr.log
        fi

        # Indent STDOUT
        if [[ -s /tmp/ansible_ping_stdout.log ]]; then
            echo "    STDOUT: |"
            sed 's/^/      /' /tmp/ansible_ping_stdout.log
        else
            echo "    STDOUT:"
        fi

        # Indent STDERR
        if [[ -s /tmp/ansible_ping_stderr.log ]]; then
            echo "    STDERR: |"
            sed 's/^/      /' /tmp/ansible_ping_stderr.log
        else
        echo "    STDERR:"
        fi
    } >> "${PLAN_FILE}"
fi


#
# run playbook in check mode
#
if [ "${SKIP_CHECK}" != "true" ]; then
    {
        echo
        echo "  ANSIBLE_PLAYBOOK_CHECK:"
        echo "    STDOUT: |"
        cd ${ANSIBLE_ROOT}

        # Run ansible-playbook in check mode, capture stdout and stderr
        if [ "$(cat inventory_static.yml)" != "" ]; then
            ansible-playbook --check ${ANSIBLE_PLAYBOOK} -i inventory_static.yml > /tmp/ansible_playbook_check_stdout.log 2> /tmp/ansible_playbook_check_stderr.log
        else
            rm inventory_static.yml
            ansible-playbook --check ${ANSIBLE_PLAYBOOK} > /tmp/ansible_playbook_check_stdout.log 2> /tmp/ansible_playbook_check_stderr.log
        fi

        # Indent STDOUT
        if [[ -s /tmp/ansible_playbook_check_stdout.log ]]; then
            sed 's/^/      /' /tmp/ansible_playbook_check_stdout.log
        else
            echo "      (none)"
        fi

        echo "    STDERR: |"
        # Indent STDERR
        if [[ -s /tmp/ansible_playbook_check_stderr.log ]]; then
            sed 's/^/      /' /tmp/ansible_playbook_check_stderr.log
        else
            echo "      (none)"
        fi
    } >> "${PLAN_FILE}"
fi

EXIT_CODE=0

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "END: Ansible plan stage" >&2
echo "⚠️ ================================================" >&2

echo "⚠️ ================================================" >&2
echo ">>TERRATEAM_PLAN_FILE: ${TERRATEAM_PLAN_FILE}" >&2
cat ${TERRATEAM_PLAN_FILE} >&2
echo "<<TERRATEAM_PLAN_FILE" >&2
echo "⚠️ ================================================" >&2

exit ${EXIT_CODE}
