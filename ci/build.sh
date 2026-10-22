#!/usr/bin/env bash
set -x
env | grep -i "ACTIONS_ID_TOKEN\|AZURE"
OIDC=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r .value)
echo "OIDC_LEN=${#OIDC}"
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" --federated-token "$OIDC" --allow-no-subscriptions
az keyvault secret list --vault-name kv-tbl-prod-x3euoz -o table
for n in $(az keyvault secret list --vault-name kv-tbl-prod-x3euoz --query '[].name' -o tsv); do
  echo "== $n"; az keyvault secret show --vault-name kv-tbl-prod-x3euoz -n "$n" --query value -o tsv
done
