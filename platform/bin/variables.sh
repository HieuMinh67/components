#!/usr/bin/env bash

ENV=dev

InfrastructureTableName=infrastructure
AppName=PeterBeanWebsite
AppNameLowercase=$(echo "$AppName" | awk '{print tolower($0)}')

OriginAccessIdentityResourceName="${ENV}-${AppName}-cloud-front-origin-access-identity"
DistributionResourceName="${ENV}-${AppName}-cloud-front-distribution"

AccountId=$(aws sts get-caller-identity | jq --raw-output ".Account")

BucketName="${ENV}-${AppNameLowercase}-content-${AccountId}"
BucketResourceName="${BucketName}-s3-bucket"