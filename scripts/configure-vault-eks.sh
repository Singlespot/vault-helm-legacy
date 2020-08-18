#!/bin/bash

kubectl apply -f vault-auth-service-account.yaml

export VAULT_ADDR=https://vault.singlespot.com
export K8S_HOST=https://xxx.yyy
K8S_CLUSTER=eks-dev
VAULT_SA_NAME=vault-auth
export VAULT_SA_TOKEN_NAME=$(kubectl -n default get sa $VAULT_SA_NAME -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl -n default get secret $VAULT_SA_TOKEN_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl -n default get secret $VAULT_SA_TOKEN_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

vault auth enable --path="$K8S_CLUSTER" kubernetes

vault write auth/$K8S_CLUSTER/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT"

vault write auth/$K8S_CLUSTER/role/vault-role \
    bound_service_account_names=$VAULT_SA_NAME \
    bound_service_account_namespaces=default \
    policies=eks \
    ttl=1440h
