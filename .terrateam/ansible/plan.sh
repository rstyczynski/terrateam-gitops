#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================"
echo "START: Ansible plan stage"

echo "TODO" > $PLAN_FILE
EXIT_CODE=0

echo "END: Ansible plan stage"
echo "⚠️ ================================================"
exit $EXIT_CODE

