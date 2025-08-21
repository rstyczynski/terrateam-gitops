#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible outputs stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo '{"status": "success", "stage": "outputs", "message": "Outputs stage completed successfully."}'
EXIT_CODE=0

echo "END: Ansible outputs stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE


