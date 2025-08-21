#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible init stage" >&2

echo "TODO Ansible init"

# removes error message from log, but does not improve 
# the speed as each stage runs in a separate container
#mkdir -p ~/.cache

# Call external debug script
source "$(dirname "$0")/debug.sh" >&2

EXIT_CODE=0

echo "⚠️ ================================================" >&2
echo "STOP: Ansible init stage" >&2
exit $EXIT_CODE