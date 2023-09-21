#!/usr/bin/env bash

function create_s3_bucket {

    BucketStateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${BucketResourceName}\"}}")

    BucketStateResultCount=$(echo $BucketStateResult | jq ".Count")

    if [[ "${BucketStateResultCount}" -gt 0 ]]; then
        printf "%s already exists \n" "${BucketName}"
        exit 0
    fi

    printf "Creating S3Bucket %s \n" "${BucketName}"

    aws s3api create-bucket --bucket "${BucketName}" --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2 >/dev/null

    aws dynamodb put-item \
    --table-name "${InfrastructureTableName}" \
    --item \
    "{\"resource_name\": {\"S\": \"${BucketResourceName}\"}}" >/dev/null


}

function update_bucket_policy_to_allow_oai {
    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${OriginAccessIdentityResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -eq 0 ]]; then
        printf "ERROR: %s does not exist \n" "cloud-front-origin-access-identity ${ENV}-${AppName}"
        exit 1
    fi

    OAIId=$(echo $StateResult | jq --raw-output '.Items[0] | .id.S')
        
    aws s3api put-bucket-policy --bucket ${BucketName} --policy "{
        \"Version\":\"2012-10-17\",
        \"Statement\":[{
            \"Sid\":\"AllowCloudFrontAccessToBucket\",
            \"Effect\":\"Allow\",
            \"Principal\":{\"AWS\":\"arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${OAIId}\"},
            \"Action\":\"s3:GetObject\",
            \"Resource\":\"arn:aws:s3:::${BucketName}/*\"
        }]
    }"

}