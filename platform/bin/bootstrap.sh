#!/usr/bin/env bash

source "$(pwd)/platform/bin/variables.sh"

source "$(pwd)/platform/bin/functions/s3.sh"
source "$(pwd)/platform/bin/functions/cloudfront.sh"

_=$(aws dynamodb describe-table --table-name "${InfrastructureTableName}" >/dev/null 2>&1)

if [[ "$?" -ne 0 ]]; then
    printf "Creating DynamoDB Table %s \n" "${InfrastructureTableName}"
    aws dynamodb create-table \
        --table-name "${InfrastructureTableName}" \
        --attribute-definitions \
        AttributeName=resource_name,AttributeType=S \
        --key-schema \
        AttributeName=resource_name,KeyType=HASH \
        --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5 >/dev/null
    sleep 3
fi

sleep 2
# aws s3api create-bucket --bucket "${BucketName}" --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2 >/dev/null
create_s3_bucket

sleep 3
create_cloud_front_origin_access_identity_and_update_bucket_policy

sleep 1
printf "Create a CloudFront Distribution with the OAI \n"
create_cloud_front_distribution    

BucketStateResult=$(aws dynamodb query \
    --table-name "${InfrastructureTableName}" \
    --key-condition-expression "resource_name = :name" \
    --expression-attribute-values "{\":name\":{\"S\":\"${BucketResourceName}\"}}")

BucketStateResultCount=$(echo $BucketStateResult | jq ".Count")

if [[ "${BucketStateResultCount}" -gt 0 ]]; then
    printf "successful %s ++" $BucketStateResultCount
else
    printf "error %s ++" $BucketStateResultCount
fi

# aws dynamodb delete-table --table-name infrastructure
# aws s3 rb s3://dev-peterbeanwebsite-terraform-state-356077346614 --force


# aws cloudfront create-distribution --distribution-config '{
#     "CallerReference":"myCallerReference2",
#     "Origins":{
#         "Quantity":1,
#         "Items":[{
#             "Id":"myS3Origin2",
#             "DomainName":"dev-peterbeanwebsite-content-356077346614.s3.us-west-2.amazonaws.com",
#             "S3OriginConfig":{
#                 "OriginAccessIdentity":"origin-access-identity/cloudfront/EC0RMHYO2MICI"
#             }
#         }]
#     },
#     "DefaultCacheBehavior":{
#         "TargetOriginId":"myS3Origin2",
#         "ViewerProtocolPolicy":"allow-all",
#         "MinTTL": 1,
#         "TrustedSigners":{
#             "Enabled":false,
#             "Quantity":0
#         },
#         "ForwardedValues":{
#             "QueryString":false,
#             "Cookies":{
#                 "Forward":"none"
#             }
#         }
#     },
#     "Comment":"myComment",
#     "Enabled":true
# }'
