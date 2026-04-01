#!/usr/bin/env bash
# deploy.sh — Build and deploy Linear Clone to a DigitalOcean droplet.
#
# Usage:
#   ./deploy.sh <droplet-ip>
#
# Requirements (local):
#   - Docker
#   - rsync
#   - SSH access to the droplet as root using ~/.ssh/linear-clone-deploy
#
# On first run the script bootstraps the server (installs Docker + Compose).

set -euo pipefail

DROPLET_IP="${1:-}"
if [[ -z "$DROPLET_IP" ]]; then
  echo "Usage: $0 <droplet-ip>" >&2
  exit 1
fi

SSH_KEY="${SSH_KEY:-$HOME/.ssh/linear-clone-deploy}"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=30"
REMOTE="root@$DROPLET_IP"
APP_DIR="/opt/linear-clone"

echo "==> Deploying to $DROPLET_IP"

# ── 1. Wait for SSH to be available ──────────────────────────────────────────
echo "==> Waiting for SSH..."
for i in $(seq 1 30); do
  if ssh $SSH_OPTS "$REMOTE" "true" 2>/dev/null; then
    break
  fi
  echo "    attempt $i/30 — retrying in 5s..."
  sleep 5
done

# ── 2. Bootstrap: install Docker if not present ───────────────────────────────
echo "==> Bootstrapping server..."
ssh $SSH_OPTS "$REMOTE" bash <<'BOOTSTRAP'
set -e
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  # Wait for cloud-init / unattended-upgrades to release the apt lock
  echo "  waiting for apt lock..."
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 3; done
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
  echo "Docker installed: $(docker --version)"
else
  echo "Docker already installed: $(docker --version)"
fi
BOOTSTRAP

# ── 3. Sync code to server ───────────────────────────────────────────────────
echo "==> Syncing code to $REMOTE:$APP_DIR ..."
ssh $SSH_OPTS "$REMOTE" "mkdir -p $APP_DIR"
rsync -az --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='.env' \
  -e "ssh $SSH_OPTS" \
  "$(dirname "$0")/" \
  "$REMOTE:$APP_DIR/"

# ── 4. Build and start containers on the server ──────────────────────────────
echo "==> Building and starting containers..."
ssh $SSH_OPTS "$REMOTE" bash <<DEPLOY
set -e
cd $APP_DIR
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d --remove-orphans
echo ""
echo "==> Running containers:"
docker compose -f docker-compose.prod.yml ps
DEPLOY

echo ""
echo "✅ Deployment complete!"
echo "   App: http://$DROPLET_IP"
