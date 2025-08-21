#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible plan stage" >&2

echo "TERRATEAM_PLAN_FILE (exported): $TERRATEAM_PLAN_FILE" >&2
echo "TERRATEAM_PLAN_FILE (argumnet): $PLAN_FILE" >&2
echo "TODO Ansible plan" > $PLAN_FILE
EXIT_CODE=0

echo "END: Ansible plan stage" >&2
echo "⚠️ ================================================" >&2

echo "⚠️ ================================================" >&2
echo ">>TERRATEAM_PLAN_FILE: $TERRATEAM_PLAN_FILE" >&2
cat $TERRATEAM_PLAN_FILE >&2
echo "<<TERRATEAM_PLAN_FILE" >&2
echo "⚠️ ================================================" >&2

exit $EXIT_CODE

