#!/usr/bin/env bash
# install_docker_ubuntu.sh — simple Docker + Compose install on Ubuntu

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

# 1) Install prerequisite packages
apt-get update -qq
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# 2) Add Docker’s official GPG key (idempotent)
if ! test -f /usr/share/keyrings/docker-archive-keyring.gpg; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
fi

# 3) Add Docker apt repo (idempotent)
DOCKER_LIST=/etc/apt/sources.list.d/docker.list
if ! grep -q download.docker.com "$DOCKER_LIST" 2>/dev/null; then
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    > "$DOCKER_LIST"
fi

# 4) Install Docker Engine, CLI, containerd, and Compose plugin
apt-get update -qq
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

# 5) Enable & start Docker
systemctl enable --now docker

# 6) Add your user to the docker group
USER_TO_ADD="${SUDO_USER:-$USER}"
if id -nG "$USER_TO_ADD" | grep -qw docker; then
  echo "✔ $USER_TO_ADD is already in the 'docker' group"
else
  usermod -aG docker "$USER_TO_ADD"
  echo "✔ Added $USER_TO_ADD to 'docker' group. Log out & back in to apply."
fi

# 7) Verify install
echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version | head -n1)"
echo "Run 'docker run hello-world' to test."

