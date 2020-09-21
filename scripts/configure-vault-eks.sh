#!/bin/bash

kubectl apply -f vault-auth.yaml
kubectl apply -f vault-auth-services.yaml

export VAULT_ADDR=https://vault.singlespot.com
export K8S_HOST=https://7C69069F587A4E20F7F54E88F95D4ED0.sk1.eu-west-1.eks.amazonaws.com
K8S_CLUSTER=eks-preprod
VAULT_SA_NAME=vault-auth
export VAULT_SA_TOKEN_NAME=$(kubectl -n default get sa $VAULT_SA_NAME -o jsonpath="{.secrets[0]['name']}")
export SA_CA_CRT=$(kubectl -n default get secret $VAULT_SA_TOKEN_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

vault auth enable --path="$K8S_CLUSTER" kubernetes

vault write auth/$K8S_CLUSTER/config \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT"

vault write auth/$K8S_CLUSTER/role/vault-role \
    bound_service_account_names=$VAULT_SA_NAME \
    bound_service_account_namespaces="*" \
    policies=eks \
    ttl=1440h
