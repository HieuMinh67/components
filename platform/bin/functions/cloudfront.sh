#!/usr/bin/env bash

function create_cloud_front_origin_access_identity_and_update_bucket_policy {
    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${OriginAccessIdentityResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -gt 0 ]]; then
        printf "%s already exists \n" "cloud-front-origin-access-identity ${ENV}-${AppName}"
        exit 0
    fi

    create_cloud_front_origin_access_identity
    sleep 15
    printf "Update S3 Bucket Policy to Allow OAI \n"
    update_bucket_policy_to_allow_oai    
}

function create_cloud_front_origin_access_identity {
    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${OriginAccessIdentityResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -gt 0 ]]; then
        printf "%s already exists \n" "cloud-front-origin-access-identity ${ENV}-${AppName}"
        exit 0
    fi

    printf "Create an Origin Access Identity (OAI) for CloudFront \n"
    OAIResult=$(aws cloudfront create-cloud-front-origin-access-identity --cloud-front-origin-access-identity-config CallerReference="${ENV}-${AppName}",Comment="")
    OAIId=$(echo $OAIResult | jq --raw-output '.CloudFrontOriginAccessIdentity.Id')
    OAIETag=$(echo $OAIResult | jq --raw-output '.ETag')
    echo OAIID is $OAIId
    echo OAIETag is $OAIETag

    aws dynamodb put-item \
        --table-name "${InfrastructureTableName}" \
        --item \
        "{\"resource_name\": {\"S\": \"${OriginAccessIdentityResourceName}\"}, \"id\": {\"S\": \"${OAIId}\"}, \"etag\": {\"S\": \"${OAIETag}\"}}" >/dev/null

}

function create_cloud_front_distribution {

    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${DistributionResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -gt 0 ]]; then
        printf "%s already exists \n" "cloud-front-distribution ${DistributionResourceName}"
        exit 0
    fi    
        
    Distribution=$(aws cloudfront create-distribution --distribution-config "{
        \"CallerReference\":\"${ENV}-${AppName}\",
        \"DefaultRootObject\":\"index.html\",
        \"Origins\":{
            \"Quantity\":1,
            \"Items\":[{
                \"Id\":\"myS3Origin\",
                \"DomainName\":\"${BucketName}.s3.us-west-2.amazonaws.com\",
                \"S3OriginConfig\":{
                    \"OriginAccessIdentity\":\"origin-access-identity/cloudfront/${OAIId}\"
                }
            }]
        },
        \"DefaultCacheBehavior\":{
            \"TargetOriginId\":\"myS3Origin\",
            \"ViewerProtocolPolicy\":\"allow-all\",
            \"MinTTL\": 1,
            \"TrustedSigners\":{
                \"Enabled\":false,
                \"Quantity\":0
            },
            \"ForwardedValues\":{
                \"QueryString\":false,
                \"Cookies\":{
                    \"Forward\":\"none\"
                }
            }
        },
        \"Comment\":\"${ENV}-${AppName}\",
        \"Enabled\":true
    }")

    DistributionETag=$(echo ${Distribution} | jq --raw-output '.ETag')
    DistributionId=$(echo ${Distribution} | jq --raw-output '.Distribution.Id')

    echo "DistributionId is $DistributionId "
    echo "DistributionETag is $DistributionETag "

    aws dynamodb put-item \
        --table-name "${InfrastructureTableName}" \
        --item \
        "{\"resource_name\": {\"S\": \"${DistributionResourceName}\"}, \"id\": {\"S\": \"${DistributionId}\"}, \"etag\": {\"S\": \"${DistributionETag}\"}}" >/dev/null

}

function get_cloud_front_distribution_host {

    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${DistributionResourceName}\"}}")

    DistributionId=$(echo $StateResult | jq --raw-output '.Items[0] | .id.S')

    aws cloudfront get-distribution --id "${DistributionId}" | jq --raw-output '.Distribution.DomainName'
}