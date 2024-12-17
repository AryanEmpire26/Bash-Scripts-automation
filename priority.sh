#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Token
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njg1MjE2NDQsImZyZXNoIjp0cnVlLCJqdGkiOiI3YzRmODZmZS05NDRlLTQ3NDMtYjNjMi0xMTVmYmUyZmRmOWQiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.ReKhYqqr-SzSYrN9BKWNA5sLkWISdBqHGEQeASq6fAQ"


# Deployment Names with Priority `P1`
DEPLOYMENT_NAMES=(
  "enrichment-pdf-be"
  "user-report-writer-non-video"
  "user-report-writer-video"
  "test-reader"
  "doubt-cron"
  "cms-be-writer"
  "user-report-reader"
  "pw-gen-ai"
  "special-ops-test-evaluation"
  "enrichment-be"
  "crm-backend"
  "nlp"
  "special-ops-content-backend"
  "special-ops-notification"
  "comment"
  "special-ops-utilities-backend"
  "user-report-writer-aits"
  "gcms-be"
  "special-ops-erp-backend"
  "pw-nurture"
  "live-kit"
  "user-report-writer-reconciliation"
  "test"
  "doubt"
  "studio-app-backend"
  "media-api-node"
  "pw-community-api"
  "form"
  "pw-sahayak"
  "sarthi-backend"
  "user-experience-reader"
  "vp"
  "mentorship"
)

# Convert Deployment Names to JSON Array
name_in_array=$(printf '"%s",' "${DEPLOYMENT_NAMES[@]}" | sed 's/,$//')

# Step 1: Fetch Deployments by Names
response=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH_TOKEN" \
  -d "{
    \"query\": \"query DeploymentQuery(\$where: DeploymentWhereInput) { DeploymentQuery(where: \$where) { edges { node { id name priority } } } }\",
    \"variables\": {
      \"where\": {
        \"nameIn\": [$name_in_array]
      }
    }
  }")

# Debug: Print the response
echo "Raw Response: $response"

# Check for Errors
errors=$(echo "$response" | jq '.errors')
if [[ "$errors" != "null" ]]; then
  echo "Error in API Response: $errors"
  exit 1
fi

# Extract Deployment Data
deployments=$(echo "$response" | jq -c '.data.DeploymentQuery.edges[]')

# Step 2: Update Priority for Each Deployment
for deployment in $deployments; do
  id=$(echo "$deployment" | jq -r '.node.id')
  name=$(echo "$deployment" | jq -r '.node.name')
  echo "Updating Deployment ID: $id, Name: $name to Priority: P1"

  # Update Deployment Priority
  update_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization: $AUTH_TOKEN" \
       -d "{
         \"query\": \"mutation DeploymentUpdate(\$deploymentUpdateId: ID!, \$input: UpdateDeploymentInput!) { DeploymentUpdate(id: \$deploymentUpdateId, input: \$input) { id name priority } }\",
         \"variables\": {
           \"deploymentUpdateId\": \"$id\",
           \"input\": {
             \"priority\": \"P1\"
           }
         }
       }")

  # Check for Errors
  errors=$(echo "$update_response" | jq '.errors')
  if [[ "$errors" != "null" ]]; then
    echo "Error updating Deployment ID: $id, Name: $name - $errors"
    continue
  fi

  echo "Successfully updated Deployment ID: $id, Name: $name to Priority: P1"
done
