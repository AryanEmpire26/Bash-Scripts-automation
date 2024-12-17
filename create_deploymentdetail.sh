#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Token
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njk5Mzg2NTksImZyZXNoIjp0cnVlLCJqdGkiOiJkMjlhZDE4OC0yYTQwLTQzNWItOTZiNy03YThmZWYzNzMyN2MiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.xCjen46rRkHdvbUDUju6hoSHocaJaMZZ6Iqtzq45vJ0"

# Step 1: Fetch deployment details with the specific environmentID
response=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH_TOKEN" \
  -d '{
    "query": "query DeploymentDetailQuery($where: DeploymentDetailWhereInput!) { DeploymentDetailQuery(where: $where) { edges { node { id deployment { id name } environment { id name } } } } }",
    "variables": {
      "where": {
        "environmentID":"f4660020-8d40-4990-9808-ac576901c7e7"
        
      }
    }
  }')

# Debug: Print the full response
echo "Raw Response: $response"

# Handle API errors
errors=$(echo "$response" | jq '.errors')
if [[ "$errors" != "null" ]]; then
  echo "Error in API Response: $errors"
  exit 1
fi

# Parse deployment detail IDs and names
deployment_details=$(echo "$response" | jq -c '.data.DeploymentDetailQuery.edges[]')
if [[ -z "$deployment_details" || "$deployment_details" == "null" ]]; then
  echo "No deployment details found for the specified environmentID."
  exit 1
fi

# Step 2: Loop through each deployment detail and update Jenkins link
for detail in $deployment_details; do
  deployment_detail_id=$(echo "$detail" | jq -r '.node.id')
  deployment_name=$(echo "$detail" | jq -r '.node.deployment.name')

  # Generate the correct Jenkins link
  argo_link="https://platform-grafana.penpencil.co/d/TdDJRqB4ka12/prod-dr-service-dashboard?from=now-30m&to=now&var-datasource=de5bad1rrnny8b&var-namespace=microservices&var-service=$deployment_name-service&var-pod=$__all&var-error_code_regex=%5B123%5D%5B0-9%5D%7B2%7D&var-interval=$__interval"

  # Debug deployment details
  echo "Updating Jenkins Link for Deployment Detail ID: $deployment_detail_id, Deployment Name: $deployment_name"

  # Send mutation request to update the Jenkins link
  update_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization: $AUTH_TOKEN" \
       -d '{
         "query": "mutation DeploymentDetailUpdate($deploymentDetailUpdateId: ID!, $input: UpdateDeploymentDetailInput!) { DeploymentDetailUpdate(id: $deploymentDetailUpdateId, input: $input) {id grafanaLink } }",
         "variables": {
           "deploymentDetailUpdateId": "'"$deployment_detail_id"'",
           "input": {
             "grafanaLink": "'"$argo_link"'"
           }
         }
       }')

  # Log the response
  errors=$(echo "$update_response" | jq '.errors')
  if [[ "$errors" != "null" ]]; then
    echo "Error updating Jenkins Link for Deployment Detail ID: $deployment_detail_id, Name: $deployment_name - $errors"
    continue
  fi

  echo "Update Response: $update_response"
  sleep 1
done
