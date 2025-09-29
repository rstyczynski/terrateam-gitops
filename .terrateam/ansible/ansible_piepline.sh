#!/bin/bash

if [ -f "ansible_piepline.yml" ]; then
    piepline_ctx=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' ansible_piepline.yml) 
else
    piepline_ctx="{}"
fi
ANSIBLE_PLAYBOOK=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.ansible_playbook // empty')
DEBUG_INIT=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.init // empty')
DEBUG_PLAN=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.plan // empty')
DEBUG_DIFF=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.diff // empty')
DEBUG_APPLY=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.apply // empty')
DEBUG_OUTPUT=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.output // empty')
DEBUG_SHARED=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.shared // empty')

SKIP_PING=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.control.skip_ping // empty')
SKIP_CHECK=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.control.skip_check // empty')
PYTHON_INFO=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.control.python_info // empty')