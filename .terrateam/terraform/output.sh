#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: Terraform outputs stage" >&2

terraform output
EXIT_CODE=0

echo "END: Terraform outputs stage" >&2
echo "⚠️ ================================================" >&2
exit $EXIT_CODE
