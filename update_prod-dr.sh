#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Token
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njk5Mzg2NTksImZyZXNoIjp0cnVlLCJqdGkiOiJkMjlhZDE4OC0yYTQwLTQzNWItOTZiNy03YThmZWYzNzMyN2MiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.xCjen46rRkHdvbUDUju6hoSHocaJaMZZ6Iqtzq45vJ0"

# Fixed environment ID
FIXED_ENVIRONMENT_ID="f4660020-8d40-4990-9808-ac576901c7e7"

# Step 1: Fetch all service
response=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization:  $AUTH_TOKEN" \
  -d '{
    "query": "query DeploymentQuery { DeploymentQuery { edges { node { id name } } } }"
  }')

# Debug: Print the full response
echo "Raw Response: $response"

# Handle API errors
errors=$(echo "$response" | jq '.errors')

if [[ "$errors" != "null" ]]; then
  echo "Error in API Response: $errors"
  exit 1
fi

# Parse deployments
deployments=$(echo "$response" | jq -c '.data.DeploymentQuery.edges[]')
if [[ -z "$deployments" || "$deployments" == "null" ]]; then
  echo "No deployments found in response."
  exit 1
fi

# Step 2: Loop through each service and send mutation requests
for deployment in $deployments; do
  deployment_name=$(echo "$deployment" | jq -r '.node.name')
  deployment_id=$(echo "$deployment" | jq -r '.node.id')

  # Generate dynamic links
  jenkins_link="https://jenkins.penpencil.co/job/$deployment_name/"
  sonarqube_link="https://sonarqube.penpencil.co/dashboard?branch=main&id=$deployment_name"
  argo_link="dr-production-$deployment_name"
  apm_link="https://apm.penpencil.co/app/apm/services/$deployment_name/overview?comparisonEnabled=false&environment=production-dr&kuery=&latencyAggregationType=avg&offset=1d&rangeFrom=now-5m&rangeTo=now-30s&serviceGroup=&transactionType=request"

  # Debug deployment details
  echo "Creating Deployment Detail for: $deployment_name"

  # Send create request
  create_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization:  $AUTH_TOKEN" \
       -d '{
         "query": "mutation DeploymentDetailCreate($input: CreateDeploymentDetailInput!) { DeploymentDetailCreate(input: $input) { deploymentID branch apmLink sonarqubeLink jenkinsLink argoLink environmentID } }",
         "variables": {
           "input": {
             "deploymentID": "'"$deployment_id"'",
             "branch": "main",
             "apmLink": "'"$apm_link"'",
             "sonarqubeLink": "'"$sonarqube_link"'",
             "jenkinsLink": "'"$jenkins_link"'",
             "argoLink": "'"$argo_link"'",
             "environmentID": "'"$FIXED_ENVIRONMENT_ID"'"
           }
         }
       }')

  echo "Create Response: $create_response"
  sleep 1
done
