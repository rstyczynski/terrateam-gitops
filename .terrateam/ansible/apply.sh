#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Ansible apply stage" >&2

source "$(dirname "$0")/../shared/debug.sh" >&2

echo "TODO: Ansible apply"
echo "CWD: $PWD"
echo "TERRATEAM_DIR: $TERRATEAM_DIR"
echo "TERRATEAM_WORKSPACE: $TERRATEAM_WORKSPACE"
echo "TERRATEAM_ROOT: $TERRATEAM_ROOT"
EXIT_CODE=0

echo "END: Ansible apply stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
