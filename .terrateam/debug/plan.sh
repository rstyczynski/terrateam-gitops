#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Debug plan stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "TODO Ansible plan stdout message. 'TODO Ansible plan file content' is sent to $PLAN_FILE"

echo "TERRATEAM_PLAN_FILE (exported): $TERRATEAM_PLAN_FILE" >&2
echo "TERRATEAM_PLAN_FILE (argumnet): $PLAN_FILE" >&2
echo "TODO Ansible plan file content" > $PLAN_FILE
EXIT_CODE=0

echo "END: Debug plan stage" >&2
echo "⚠️ ================================================" >&2

echo "⚠️ ================================================" >&2
echo ">>TERRATEAM_PLAN_FILE: $TERRATEAM_PLAN_FILE" >&2
cat $TERRATEAM_PLAN_FILE >&2
echo "<<TERRATEAM_PLAN_FILE" >&2
echo "⚠️ ================================================" >&2

exit $EXIT_CODE

