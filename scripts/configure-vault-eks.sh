#!/bin/bash

kubectl apply -f vault-auth.yaml

export VAULT_ADDR=https://vault.singlespot.com
export K8S_HOST=https://05E62636E8DEFCA20777C07A373E9F9A.yl4.eu-west-1.eks.amazonaws.com
K8S_CLUSTER=eks-dev
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

# certbot certonly --dns-ovh --dns-ovh-credentials ~/.singlespot-ovhapi -d vault.singlespot.com --rsa-key-size 4096
# --config-dir ~/certbot-singlespot/config --work-dir ~/certbot-singlespot/work --logs-dir ~/certbot-singlespot/logs

# Since the directories used by Certbot are configurable, Certbot will write a lock file for all of the directories it
# uses. This include Certbot’s --work-dir, --logs-dir, and --config-dir. By default these are /var/lib/letsencrypt,
# /var/log/letsencrypt, and /etc/letsencrypt respectively. Additionally if you are using Certbot with Apache or nginx
# it will lock the configuration folder for that program, which are typically also in the /etc directory.

# kubectl create secret generic letsencrypt-ovhapi --from-file=.ovhapi=.singlespot-ovhapi -n vault-dev
