#!/usr/bin/env bash
set -e

echo "🚀 Deploying Co-op Cloud workshop..."

cd terraform
terraform apply \
  -var="hcloud_token=$HCLOUD_TOKEN" \
  -var="domain=codecrispi.es" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -auto-approve

echo "⏳ Waiting for servers to be ready..."

# Wait for SSH + Docker to be ready on each server
terraform output -json participant_ips | jq -r 'keys[]' | while read participant; do
  echo "Checking $participant.codecrispi.es..."
  
  # Wait for SSH to be available
  while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no workshop@$participant.codecrispi.es "exit" 2>/dev/null; do
    echo "  SSH not ready yet, retrying in 10s..."
    sleep 10
  done
  
  # Wait for Docker + abra to be ready
  while ! ssh -o StrictHostKeyChecking=no workshop@$participant.codecrispi.es "docker info && which abra" &>/dev/null; do
    echo "  Docker/abra not ready yet, retrying in 5s..."
    sleep 5
  done
  
  echo "  ✅ $participant ready!"
done

echo "🔧 Setting up each server..."
terraform output -json participant_ips | jq -r 'keys[]' | while read participant; do
  echo "Configuring $participant..."
  
  ssh -o StrictHostKeyChecking=no workshop@$participant.codecrispi.es << EOF
    # Deploy Traefik
    abra app deploy traefik.$participant.codecrispi.es
    
    # Wait for Traefik to be ready
    until curl -f https://traefik.$participant.codecrispi.es/ping 2>/dev/null; do
      echo "Waiting for Traefik..."
      sleep 5
    done
    
    echo "✅ $participant fully configured!"
EOF
done

echo "🎉 Workshop ready! Participants can access their servers."
