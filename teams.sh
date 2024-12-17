#!/bin/bash

# Base URL
BASE_URL="https://idp-api-dev.penpencil.co/query"

# Authorization Toke
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njg1MjE2NDQsImZyZXNoIjp0cnVlLCJqdGkiOiI3YzRmODZmZS05NDRlLTQ3NDMtYjNjMi0xMTVmYmUyZmRmOWQiLCJzdWIiOiI3YWRhNjM2NC0yODgzLTQzZDItYmMwZi04NGVkNWMwNGMxMTUifQ.ReKhYqqr-SzSYrN9BKWNA5sLkWISdBqHGEQeASq6fAQ"

# Deployment and Team List
DEPLOYMENT_TEAMS=(
  "mqtt-emoji=user-experience-content-consumption"
  "pay-backend=new-business"
  "special-ops-test-evaluation=internal-tools-and-automation"
  "user-experience-reader=new-business"
  "doubt=user-experience-content-consumption"
  "media-api-node=user-experience-content-consumption"
  "reels=user-engagement"
  "pw-store-crons=pw-store"
  "cdp-fastapi=Data Services"
  "third-party-integration=vidyapeeth"
  "user-notification=new-business"
  "core-utilities=Backend Platform"
  "test=user-experience-non-content-consumption"
  "batch-scheduling-consumer=revenue-growth"
  "special-ops-user-utilities-backend=internal-tools-and-automation"
  "pw-ai-grader=Data Services"
  "pw-gen-ai=user-engagement"
  "pw-ds=Data Services"
  "batch-scheduling=revenue-growth"
  "batches-reader=revenue-growth"
  "crm-backend=internal-tools-and-automation"
  "penpencil-backend-admin=internal-tools-and-automation"
  "batches-exp=revenue-growth"
  "auth=user-experience-content-consumption"
  "auth-uwebsocket=user-experience-content-consumption"
  "pw-sahayak=user-engagement"
  "curiousjr-k8-backend=school-tech"
  "cms-be-writer=user-acquisition"
  "cms-be=user-acquisition"
  "curious-jr-backend=school-tech"
  "batches=revenue-growth"
  "comment=user-experience-content-consumption"
  "core-utilities-go=Backend Platform"
  "engagement=user-engagement"
  "enrichment-be=user-experience-non-content-consumption"
  "doubt-cron=user-experience-content-consumption"
  "form=marktech"
  "enrichment-pdf-be=user-experience-non-content-consumption"
  "central-socket=user-experience-content-consumption"
  "engagement-writer=user-engagement"
  "gcms-be=user-acquisition"
  "media=user-engagement"
  "mentorship=user-engagement"
  "global-sitemap-generator=user-acquisition"
  "live-kit=saarthi"
  "nuggetoverse=new-business"
  "penpencil-backend=revenue-growth"
  "pay-background=new-business"
  "panva-backend=Innovation"
  "order-management=new-business"
  "mqtt=user-experience-content-consumption"
  "pay-imfi=new-business"
  "penpencil-backend-exp=revenue-growth"
  "pay-payment=new-business"
  "penpencil-backend-beta=new-business"
  "pw-community-api=user-engagement"
  "penpencil-backend-exp-beta=revenue-growth"
  "payment=new-business"
  "pw-nurture=school-tech"
  "pw-live-class=user-experience-content-consumption"
  "pw-store=pw-store"
  "pw-talk=new-business"
  "question-bank-generator=internal-tools-and-automation"
  "slidemap-backend=internal-tools-and-automation"
  "search=user-engagement"
  "studio-app-backend=internal-tools-and-automation"
  "special-ops-batch-audit=internal-tools-and-automation"
  "special-ops-notification=internal-tools-and-automation"
  "sarthi-backend=saarthi"
  "special-ops-content-backend=internal-tools-and-automation"
  "test-reader=user-experience-non-content-consumption"
  "student-acquisition-be=user-acquisition"
  "uc-store-crons=pw-store"
  "special-ops-utilities-backend=internal-tools-and-automation"
  "user-microservice=user-experience-content-consumption"
  "uc-store=pw-store"
  "special-ops-erp-backend=internal-tools-and-automation"
  "user-experience-writer=new-business"
  "vp=vidyapeeth"
  "video-trim=data-science"
  "user-report-writer-reconciliation=user-experience-non-content-consumption"
  "user-report-reader=user-experience-non-content-consumption"
  "video-stats-reader=user-experience-non-content-consumption"
  "video-stats-writer=user-experience-non-content-consumption"
  "user-report-writer-video=user-experience-non-content-consumption"
  "user-report-writer-non-video=user-experience-non-content-consumption"
  "nlp=Data Services"
  "user-report-writer-aits=user-experience-non-content-consumption"
  "pdf-stats=revenue-growth"
  "unigo-backend=new-business"
)

# Process Each Deployment-Team Pair
get_team_id() {
  local team_name="$1"
  response=$(curl -s -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: $AUTH_TOKEN" \
    -d "{
      \"query\": \"query TeamQuery(\$where: TeamWhereInput) { TeamQuery(where: \$where) { edges { node { id } } } }\",
      \"variables\": {
        \"where\": {
          \"name\": \"$team_name\"
        }
      }
    }")

  # Extract Team ID
  echo "$response" | jq -r '.data.TeamQuery.edges[0].node.id'
}

# Loop through each Deployment-Team Pair
for pair in "${DEPLOYMENT_TEAMS[@]}"; do
  name=$(echo "$pair" | cut -d '=' -f 1)
  team_name=$(echo "$pair" | cut -d '=' -f 2)

  # Step 1: Fetch Team ID
  team_id=$(get_team_id "$team_name")
  if [[ -z "$team_id" || "$team_id" == "null" ]]; then
    echo "Team $team_name not found. Skipping deployment $name..."
    continue
  fi

  # Step 2: Fetch Deployment ID
  response=$(curl -s -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: $AUTH_TOKEN" \
    -d "{
      \"query\": \"query DeploymentQuery(\$where: DeploymentWhereInput) { DeploymentQuery(where: \$where) { edges { node { id } } } }\",
      \"variables\": {
        \"where\": {
          \"name\": \"$name\"
        }
      }
    }")

  deployment_id=$(echo "$response" | jq -r '.data.DeploymentQuery.edges[0].node.id')
  if [[ -z "$deployment_id" || "$deployment_id" == "null" ]]; then
    echo "Deployment $name not found. Skipping..."
    continue
  fi

  echo "Updating Deployment ID: $deployment_id, Name: $name to Team ID: $team_id"

  # Step 3: Update Deployment with Team ID
  update_response=$(curl -s -X POST "$BASE_URL" \
       -H "Content-Type: application/json" \
       -H "Authorization: $AUTH_TOKEN" \
       -d "{
         \"query\": \"mutation DeploymentUpdate(\$deploymentUpdateId: ID!, \$input: UpdateDeploymentInput!) { DeploymentUpdate(id: \$deploymentUpdateId, input: \$input) { teamID } }\",
         \"variables\": {
           \"deploymentUpdateId\": \"$deployment_id\",
           \"input\": {
             \"teamID\": \"$team_id\"
           }
         }
       }")

  # Check for Errors
  errors=$(echo "$update_response" | jq '.errors')
  if [[ "$errors" != "null" ]]; then
    echo "Error updating Deployment ID: $deployment_id, Name: $name - $errors"
    continue
  fi

  echo "Successfully updated Deployment ID: $deployment_id, Name: $name to Team ID: $team_id"
done