#!/usr/bin/env bash
set -e

echo "Deploying Co-op Cloud workshop..."

cd terraform
terraform apply \
  -var="hcloud_token=$HCLOUD_TOKEN" \
  -var="hetzner_dns_token=$HETZNER_DNS_TOKEN" \
  -var="dns_zone_id=$DNS_ZONE_ID" \
  -var="domain=codecrispi.es" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -auto-approve

echo "Waiting for servers to be ready..."

terraform output -json participant_ips | jq -r 'keys[]' | while read participant; do
  echo "Checking $participant.codecrispi.es..."
  
  while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no workshop@$participant.codecrispi.es "exit" 2>/dev/null; do
    echo "  SSH not ready yet, retrying in 10s..."
    sleep 10
  done
  
  while ! ssh -o StrictHostKeyChecking=no workshop@$participant.codecrispi.es "docker info && which abra" &>/dev/null; do
    echo "  Docker/abra not ready yet, retrying in 5s..."
    sleep 5
  done
  
  echo "  $participant ready!"
done

echo "Setting up each server..."
terraform output -json participant_ips | jq -r 'keys[]' | while read participant; do
  echo "Configuring $participant..."
  
  ssh -o StrictHostKeyCheckking=no workshop@$participant.codecrispi.es << EOF
    abra app deploy traefik.$participant.codecrispi.es
    
    until curl -f https://traefik.$participant.codecrispi.es/ping 2>/dev/null; do
      echo "Waiting for Traefik..."
      sleep 5
    done
    
    echo "$participant fully configured!"
EOF
done

echo "Workshop ready! Participants can access their servers."
