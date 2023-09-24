#!/usr/bin/env bash

set -eu

source "$(pwd)/platform/bin/variables.sh"

cd "${ProjectDistPath}"

case ${ENV} in
  preview)
    echo "Deploy preview"
    aws s3 cp ./ "s3://${BucketName}/${BRANCH}/" --recursive
    ;;
  dev)
    echo "Deploy dev"
    aws s3 cp ./ "s3://${BucketName}/" --recursive
    ;;
  prod)
  aws s3 cp ./ "s3://${BucketName}/" --recursive
    echo "Deploy prod"
    ;;
  *)
    echo "Unsupported ENV ${ENV}"
    exit 1
    ;;
esac
