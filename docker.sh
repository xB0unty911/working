#!/bin/bash
set -e

# Checking and installing Docker
if ! command -v docker &>/dev/null; then
  echo "Docker not found - installing..."
  sudo apt update
  sudo apt install -y \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release

  # Add the official Docker GPG key if it hasn't been added yet
  if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  fi

  # Adding a repository
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
     https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install Docker Engine and containerd
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io

  echo "✔ Docker is installed"
else
  echo "✔ Docker already exists ($(docker --version))"
fi

# Check and install Docker Compose (CLI plugin v2 and binary)
if ! command -v docker-compose &>/dev/null; then
  echo "Docker Compose not found - installing..."
  sudo apt update
  sudo apt install -y wget jq

  # We take the latest version from GitHub API
  COMPOSE_VER=$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest \
    | jq -r ".tag_name")

  # Install the old binary for compatibility (if needed)
  sudo wget -O /usr/local/bin/docker-compose \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)"
  sudo chmod +x /usr/local/bin/docker-compose

  # And we install the modern plugin v2
  DOCKER_CLI_PLUGINS=${DOCKER_CLI_PLUGINS:-"$HOME/.docker/cli-plugins"}
  mkdir -p "$DOCKER_CLI_PLUGINS"
  curl -fsSL \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" \
    -o "${DOCKER_CLI_PLUGINS}/docker-compose"
  chmod +x "${DOCKER_CLI_PLUGINS}/docker-compose"

  echo "✔ Docker Compose ${COMPOSE_VER} installed"
else
  echo "✔ Docker Compose is already there ($(docker-compose --version))"
fi
