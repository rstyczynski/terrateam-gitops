#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible outputs stage" >&2

# load pipeline execution context from the file ansible_piepline.yml
source "$(dirname "$0")/ansible_piepline.sh"


source "$(dirname "$0")/../shared/debug.sh" >&2

echo '{"status": "success", "stage": "outputs", "message": "TEST: Outputs stage completed successfully."}'
EXIT_CODE=0

echo "END: Ansible outputs stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE


