#!/bin/bash

echo "⚠️ ================================================" >&2
echo "START: post-hook" >&2

echo ">>TERRATEAM_PLAN_FILE: $TERRATEAM_PLAN_FILE"
cat $TERRATEAM_PLAN_FILE >&2
echo "<<TERRATEAM_PLAN_FILE"
echo "END: post-hook" >&2
echo "⚠️ ================================================" >&2