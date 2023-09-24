#!/usr/bin/env bash

set -eu

source "$(pwd)/platform/bin/variables.sh"

case ${ENV} in
  preview)
    echo "Remove a preview"
    aws s3 rm "s3://${BucketName}/${BRANCH}" --recursive
    ;;
  dev)
    echo "Removing DEV is not supported"
    ;;
  prod)
    echo "Removing PROD is not supported"
    ;;
  *)
    echo "Unsupported ENV ${ENV}"
    exit 1
    ;;
esac
