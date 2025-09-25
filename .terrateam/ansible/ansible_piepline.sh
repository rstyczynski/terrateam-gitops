#!/bin/bash

if [ -f "ansible_piepline.yml" ]; then
    piepline_ctx=$(python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' ansible_piepline.yml) 
else
    piepline_ctx="{}"
fi

ansible_playbook=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.ansible_playbook // empty')
debug_init=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.init // empty')
debug_plan=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.plan // empty')
debug_diff=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.diff // empty')
debug_apply=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.apply // empty')
debug_output=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.output // empty')
debug_shared=$(echo "$piepline_ctx" | jq -r '.ansible_piepline.debug.shared // empty')