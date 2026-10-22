#!/usr/bin/env bash
set -x
OIDC=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r .value)
TEN=3205c325-06a5-4171-9ce8-ffc5e6c2845e
exch() {
  curl -sS -X POST "https://login.microsoftonline.com/$TEN/oauth2/v2.0/token" \
    -d client_id="$1" -d grant_type=client_credentials -d scope="$2" \
    -d client_assertion_type="urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    -d client_assertion="$OIDC" | jq -r '.access_token // .error_description'
}
echo "loaded"
