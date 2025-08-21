#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible apply stage" >&2

# Call external debug script
source "$(dirname "$0")/debug.sh" >&2

echo "TODO: Ansible apply"
EXIT_CODE=0

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
