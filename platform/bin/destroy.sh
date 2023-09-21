#!/usr/bin/env bash

set -eu 

source "$(pwd)/platform/bin/variables.sh"

DistributionStateResult=$(aws dynamodb query \
    --table-name "${InfrastructureTableName}" \
    --key-condition-expression "resource_name = :name" \
    --expression-attribute-values "{\":name\":{\"S\":\"${DistributionResourceName}\"}}")

DistributionId=$(echo $DistributionStateResult | jq --raw-output '.Items[0] | .id.S')
DistributionETag=$(echo $DistributionStateResult | jq --raw-output '.Items[0] | .etag.S')
# We can also get DistributionETag directly from AWS API
# DistributionETag=$(aws cloudfront get-distribution-config --id "${DistributionId}" | jq --raw-output '.ETag')

DistributionConfigDisabled=$(aws cloudfront get-distribution-config --id "${DistributionId}" | jq '.DistributionConfig.Enabled = false | .DistributionConfig ')

DistributionUpdateResult=$(aws cloudfront update-distribution \
    --id "${DistributionId}" \
    --if-match "${DistributionETag}" --distribution-config  "${DistributionConfigDisabled}")
printf "Disabled cloudfront \n"
DistributionETag=$(echo $DistributionUpdateResult | jq --raw-output '.ETag')
printf "Updated ETag is ${DistributionETag} \n"

aws dynamodb put-item \
    --table-name "${InfrastructureTableName}" \
    --item \
    "{\"resource_name\": {\"S\": \"${DistributionResourceName}\"}, \"id\": {\"S\": \"${DistributionId}\"}, \"etag\": {\"S\": \"${DistributionETag}\"}}" >/dev/null


sleep 5
printf "Let's wait for another 10 seconds to give AWS some time to breathe \n"
sleep 30
printf "Let's wait a bit further \n"
sleep 30
printf "Maybe another 30 secs \n"
sleep 30
printf "How about 5 minutes \n"
sleep 300

printf "Now trying to delete the distribution"
sleep 5
aws cloudfront delete-distribution --id "${DistributionId}" --if-match "${DistributionETag}"
printf "Distribution deleted"

OriginAccessIdentityStateResult=$(aws dynamodb query \
    --table-name "${InfrastructureTableName}" \
    --key-condition-expression "resource_name = :name" \
    --expression-attribute-values "{\":name\":{\"S\":\"${OriginAccessIdentityResourceName}\"}}")

OAIId=$(echo $OriginAccessIdentityStateResult | jq --raw-output '.Items[0] | .id.S')
OAIETag=$(echo $OriginAccessIdentityStateResult | jq --raw-output '.Items[0] | .etag.S')

aws cloudfront delete-cloud-front-origin-access-identity --id ${OAIId} --if-match ${OAIETag}
printf "OAI deleted"
sleep 1

aws s3 rb "s3://${BucketName}" --force
printf "Bucket deleted"
sleep 1

aws dynamodb delete-table --table-name infrastructure > /dev/null
printf "DynamoDB table deleted"
sleep 1
