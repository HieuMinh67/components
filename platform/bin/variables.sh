#!/usr/bin/env bash

ENV=${ENV:-prod}
Region=${Region:-us-west-2}

ProjectPath="apps/gatsby-showcase"
ProjectDistPath="${ProjectPath}/public"

InfrastructureTableName=infrastructure
AppName=PeterBeanWebsite
AppNameLowercase=$(echo "$AppName" | awk '{print tolower($0)}')

OriginAccessIdentityResourceName="${ENV}-${AppName}-cloud-front-origin-access-identity"
DistributionResourceName="${ENV}-${AppName}-cloud-front-distribution"

AccountId=$(aws sts get-caller-identity | jq --raw-output ".Account")

BucketName="${ENV}-${AppNameLowercase}-content-${AccountId}"
BucketResourceName="${BucketName}-s3-bucket"
WhitelistedIps="44.227.129.192"
BucketWebsiteHost="${BucketName}.s3-website-${Region}.amazonaws.com"
BucketS3Host="${BucketName}.s3.${Region}.amazonaws.com"