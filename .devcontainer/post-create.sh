#!/bin/bash

set -e

echo "🚀 Setting up development environment..."

# Verify installations
echo "✅ Verifying installations..."
echo "Docker version:"
docker --version

echo "Docker Compose version:"
docker compose version

# Install step-cli for certificate management
echo "📦 Installing step-cli..."
wget -O step.tar.gz https://dl.smallstep.com/gh-release/cli/gh-release-header/v0.25.0/step_linux_0.25.0_amd64.tar.gz
tar -xzf step.tar.gz
sudo mv step_0.25.0/bin/step /usr/local/bin/
rm -rf step_0.25.0 step.tar.gz

echo "step-cli version:"
step version

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p pki

# Setup git safe directory
echo "🔒 Configuring git safe directory..."
git config --global --add safe.directory /workspaces/infini-playground

# Install useful shell tools
echo "📦 Installing additional tools..."
sudo apt-get update
sudo apt-get install -y \
    jq \
    curl \
    wget \
    vim \
    net-tools \
    dnsutils \
    iputils-ping \
    telnet \
    netcat

echo ""
echo "✨ Development environment ready!"
echo ""
echo "Quick start commands:"
echo "  make help          - Show all available commands"
echo "  make pki-init      - Generate certificates"
echo "  make wan           - Create Docker network"
echo "  make up-all        - Start all services"
echo "  make down-all      - Stop all services"
echo ""