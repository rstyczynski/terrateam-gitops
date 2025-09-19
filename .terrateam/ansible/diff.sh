#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible diff stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "Ansible will be executed in the following context:"
cat $TERRATEAM_PLAN_FILE


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

# Convert YAML → JSON on the fly
json=$(python3 - <<'EOF'
import sys, yaml, json
with open(sys.argv[1], "r") as f:
    print(json.dumps(yaml.safe_load(f)))
EOF
"$TERRATEAM_PLAN_FILE")

echo "$json" | jq

# Extract values with jq
playbook=$(jq -r '.ansible_execution_context.ANSIBLE_PLAYBOOK' <<<"$json")
root=$(jq -r '.ansible_execution_context.ENV.TERRATEAM_ROOT' <<<"$json")
dir=$(jq -r '.ansible_execution_context.ENV.TERRATEAM_DIR' <<<"$json")
workspace=$(jq -r '.ansible_execution_context.ENV.TERRATEAM_WORKSPACE' <<<"$json")
cfg=$(jq -r '.ansible_execution_context.ANSIBLE_CUSTOM_CFG' <<<"$json")

echo "Playbook: $playbook"
echo "Root: $root"
echo "Dir: $dir"
echo "Workspace: $workspace"
echo "Custom CFG:"
echo "$cfg"


EXIT_CODE=0

echo "END: Ansible diff stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
