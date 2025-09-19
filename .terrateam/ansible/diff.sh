#!/bin/bash

PLAN_FILE=$1

echo "⚠️ ================================================" >&2
echo "START: Ansible diff stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "TODO Ansible diff stdout message. Here is the content of $TERRATEAM_PLAN_FILE prepared at plan stage:"
cat $TERRATEAM_PLAN_FILE

echo "CWD: $PWD"
echo "TERRATEAM_DIR: $TERRATEAM_DIR"
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE"
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT"

EXIT_CODE=0

echo "END: Ansible diff stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
