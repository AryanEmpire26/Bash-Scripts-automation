#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Token
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njc5NDQ2ODQsImZyZXNoIjp0cnVlLCJqdGkiOiJiYjQwODIwNS1kOTBjLTQyZWYtOWQ5NC1hMzJlNTc4OTFlMzAiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.u0AVdfqWupO60DW7s_U7IWZuUV35t0zM6xthCmmN5hs"

# Step 1: Fetch all deployment IDs and names
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

# Parse deployment IDs and names
deployments=$(echo "$response" | jq -c '.data.DeploymentQuery.edges[]')
if [[ -z "$deployments" || "$deployments" == "null" ]]; then
  echo "No deployments found in response."
  exit 1
fi

# Step 2: Loop through each deployment and send updates
for deployment in $deployments; do
  id=$(echo "$deployment" | jq -r '.node.id')
  name=$(echo "$deployment" | jq -r '.node.name')

  # Debug deployment details
  echo "Updating Deployment ID: $id, Name: $name"

  # Send update request
  update_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization:  $AUTH_TOKEN" \
       -d '{
         "query": "mutation DeploymentUpdate($deploymentUpdateId: ID!, $input: UpdateDeploymentInput!) { DeploymentUpdate(id: $deploymentUpdateId, input: $input) { language framework } }",
         "variables": {
           "deploymentUpdateId": "'"$id"'",
           "input": {
             "language": "JavaScript",
             "framework": "NodeJs"
           }
         }
       }')

  # Log the response
  errors=$(echo "$update_response" | jq '.errors')
  if [[ "$errors" != "null" ]]; then
    echo "Error updating deployment ID: $id, Name: $name - $errors"
    continue
  fi

  echo "Update Response: $update_response"
  sleep 1
done
