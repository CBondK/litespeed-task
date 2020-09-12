#!/bin/bash
set -o allexport; source ../.env
set -x
#TMP_DIR='/tmp/lsws-installation'
TMP_DIR="../$(dirname "$0")"
echo $TMP_DIR
