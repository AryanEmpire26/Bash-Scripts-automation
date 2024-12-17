#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Token
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njc5NDQ2ODQsImZyZXNoIjp0cnVlLCJqdGkiOiJiYjQwODIwNS1kOTBjLTQyZWYtOWQ5NC1hMzJlNTc4OTFlMzAiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.u0AVdfqWupO60DW7s_U7IWZuUV35t0zM6xthCmmN5hs"

# Step 1: Fetch all services
response=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization:  $AUTH_TOKEN" \
  -d '{
    "query": "query { DeploymentDetailQuery { edges { node { id deployment { name } environment { name } } } } }"
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
deployments=$(echo "$response" | jq -c '.data.DeploymentDetailQuery.edges[]')
if [[ -z "$deployments" || "$deployments" == "null" ]]; then
  echo "No deployments found in response."
  exit 1
fi

# Step 2: Loop through each service and send updates
for deployment in $deployments; do
  id=$(echo "$deployment" | jq -r '.node.id')
  deployment_name=$(echo "$deployment" | jq -r '.node.deployment.name')
  environment_name=$(echo "$deployment" | jq -r '.node.environment.name')

  # Generate dynamic links
  jenkins_link="https://jenkins.penpencil.co/job/$environment_name/job/$deployment_name/"
  grafana_link="https://platform-grafana.penpencil.co/d/TdDJRqB4ka/service-dashboard?from=now-6h&to=now&var-service=${deployment_name}-service"
  sonarqube_link="https://sonarqube.penpencil.co/dashboard?branch=main&id=$deployment_name"
  argo_link="$(echo "$environment_name" | tr '[:upper:]' '[:lower:]')-$deployment_name"

  # Debug deployment details
  echo "Updating Deployment: $deployment_name"
  echo "Environment: $environment_name"

  # Send update request
  update_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization:  $AUTH_TOKEN" \
       -d '{
         "query": "mutation DeploymentDetailUpdate($deploymentDetailUpdateId: ID!, $input: UpdateDeploymentDetailInput!) { DeploymentDetailUpdate(id: $deploymentDetailUpdateId, input: $input) { id branch jenkinsLink grafanaLink sonarqubeLink argoLink } }",
         "variables": {
           "deploymentDetailUpdateId": "'"$id"'",
           "input": {
             "branch": "main",
             "jenkinsLink": "'"$jenkins_link"'",
             "grafanaLink": "'"$grafana_link"'",
             "sonarqubeLink": "'"$sonarqube_link"'",
             "argoLink": "'"$argo_link"'"
           }
         }
       }')

  echo "Update Response: $update_response"
  sleep 1
done
