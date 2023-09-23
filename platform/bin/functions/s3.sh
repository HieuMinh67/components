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

    aws s3api create-bucket --bucket "${BucketName}" --region "${Region}" --create-bucket-configuration "LocationConstraint=${Region}" >/dev/null

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

function enable_static_website_for_s3_bucket {
    aws s3 website "s3://${BucketName}/" --index-document index.html --error-document error.html
}

function allow_whitelisted_access_to_s3_bucket {
    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${BucketResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -eq 0 ]]; then
        printf "ERROR: %s does not exist \n" "S3 bucket for ${ENV}-${AppName}"
        exit 1
    fi
    
    WhitelistedIpsItemConfig=$(echo "${StateResult}" | jq --raw-output ".Items[0].whitelisted_ips.S = \"${WhitelistedIps}\" ")
    IsPublicItemConfig=$(echo "${WhitelistedIpsItemConfig}" | jq ".Items[0].is_public.BOOL = false")
    FinalItemConfig=$(echo "${WhitelistedIpsItemConfig}" | jq --raw-output ".Items[0]")

    # $(echo $StateResult | jq --raw-output '.Items[0] | .whitelisted_ips.S')

    aws s3api delete-public-access-block --bucket "${BucketName}"

    aws s3api put-bucket-policy --bucket ${BucketName} --policy "{
        \"Version\":\"2012-10-17\",
        \"Statement\":[{
            \"Sid\":\"AllowWhitelistedIpsAccessToBucket\",
            \"Effect\":\"Allow\",
            \"Principal\":\"*\",
            \"Action\":\"s3:GetObject\",
            \"Resource\":\"arn:aws:s3:::${BucketName}/*\",
            \"Condition\": {
				\"ForAnyValue:StringEquals\": {
					\"aws:SourceIp\": $(echo "${WhitelistedIps}" | jq -Rc 'split(",")')
				}
			}
        }]
    }"

    aws dynamodb put-item \
    --table-name "${InfrastructureTableName}" \
    --item \
    "${FinalItemConfig}" >/dev/null
}

function allow_public_access_to_s3_bucket {
    StateResult=$(aws dynamodb query \
        --table-name "${InfrastructureTableName}" \
        --key-condition-expression "resource_name = :name" \
        --expression-attribute-values "{\":name\":{\"S\":\"${BucketResourceName}\"}}")

    StateResultCount=$(echo $StateResult | jq ".Count")

    if [[ "${StateResultCount}" -eq 0 ]]; then
        printf "ERROR: %s does not exist \n" "S3 bucket for ${ENV}-${AppName}"
        exit 1
    fi

    IsPublic=$(echo $StateResult | jq --raw-output '.Items[0] | .id.BOOL')
    if [[ "${IsPublic}" == "true" ]]; then
        printf "Bucket already allows public access \n"
        exit 0
    fi

    WhitelistedIpsItemConfig=$(echo "${StateResult}" | jq --raw-output ".Items[0].whitelisted_ips.S = \"${WhitelistedIps}\" ")
    IsPublicItemConfig=$(echo "${WhitelistedIpsItemConfig}" | jq ".Items[0].is_public.BOOL = true")
    FinalItemConfig=$(echo "${WhitelistedIpsItemConfig}" | jq --raw-output ".Items[0]")

    # $(echo $StateResult | jq --raw-output '.Items[0] | .whitelisted_ips.S')

    aws s3api delete-public-access-block --bucket "${BucketName}"

    aws s3api put-bucket-policy --bucket ${BucketName} --policy "{
        \"Version\":\"2012-10-17\",
        \"Statement\":[{
            \"Sid\":\"AllowWhitelistedIpsAccessToBucket\",
            \"Effect\":\"Allow\",
            \"Principal\":\"*\",
            \"Action\":\"s3:GetObject\",
            \"Resource\":\"arn:aws:s3:::${BucketName}/*\",
            \"Condition\": {
				\"ForAnyValue:StringEquals\": {
					\"aws:SourceIp\": $(echo "${WhitelistedIps}" | jq -Rc 'split(",")')
				}
			}
        }]
    }"

    aws dynamodb put-item \
    --table-name "${InfrastructureTableName}" \
    --item \
    "${FinalItemConfig}" >/dev/null
}