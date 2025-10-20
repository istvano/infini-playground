# Devcontainer Setup for Infini Playground

This devcontainer provides a complete development environment for the Infini Playground project with:

## Features

- **Java Development Kit (JDK 21)** - Latest LTS version of Java
- **Docker-in-Docker** - Run Docker commands and docker-compose inside the container
- **Kubernetes-in-Docker (KinD)** - Create local Kubernetes clusters for testing
- **kubectl & Helm** - Kubernetes command-line tools
- **step-cli** - Certificate management tool
- **VSCode Extensions** - Pre-configured Java, Docker, Kubernetes, and YAML support

## Getting Started

1. **Open in VS Code**: 
   - Open this folder in VS Code
   - Click "Reopen in Container" when prompted
   - Or use Command Palette (F1) → "Dev Containers: Reopen in Container"

2. **Wait for Setup**: 
   - The container will build and run the post-create script
   - This installs all necessary tools

3. **Start Working**:
   ```bash
   # View available commands
   make help
   
   # Initialize certificates
   make pki-init
   
   # Create Docker network
   make wan
   
   # Start all services
   make up-all
   ```

## Available Tools

- **Docker**: `docker --version`
- **Docker Compose**: `docker compose version`
- **kubectl**: `kubectl version --client`
- **KinD**: `kind version`
- **step-cli**: `step version`
- **Java**: `java -version`

## Working with Kubernetes in Docker (KinD)

Create a local Kubernetes cluster:
```bash
# Create a cluster
kind create cluster --name infini-test

# List clusters
kind get clusters

# Delete a cluster
kind delete cluster --name infini-test
```

## Port Forwarding

The following ports are automatically forwarded:
- **8080**: HAProxy HTTP
- **8443**: HAProxy HTTPS
- **11222-11224**: Infinispan instances
- **8180, 8280, 8380**: Keycloak instances

## Docker Network

The devcontainer uses `--network=host` to allow seamless communication between containers started via docker-compose and the devcontainer itself.

## Privileged Mode

The container runs in privileged mode to support:
- Docker-in-Docker
- Kubernetes-in-Docker (KinD)
- Network management

## Troubleshooting

### Docker socket issues
If you encounter Docker socket permission issues:
```bash
sudo chmod 666 /var/run/docker.sock
```

### KinD cluster creation fails
Ensure the devcontainer is running in privileged mode (already configured).

### Port conflicts
If ports are already in use, modify the `forwardPorts` in `devcontainer.json`.

## Customization

Edit `.devcontainer/devcontainer.json` to:
- Add more VS Code extensions
- Change Java version
- Modify port forwarding
- Add custom tools in `post-create.sh`
