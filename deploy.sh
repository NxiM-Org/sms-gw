#!/bin/bash
set -e

echo "🔧 Starting deployment..."

# Default values
DEFAULT_REGISTRY="nxim"
DEFAULT_TAG="latest"

# Parse arguments
REGISTRY=${1:-$DEFAULT_REGISTRY}
TAG=${2:-$DEFAULT_TAG}

if [ -z "$REGISTRY" ]; then
  echo "❌ No registry specified. Usage: ./deploy.sh [registry] <tag>"
  echo "   Example: ./deploy.sh nxim v1.2.3"
  echo "   Example: ./deploy.sh your-registry.com:5000 v1.2.3"
  exit 1
fi

echo "📦 Using registry: $REGISTRY"
echo "📦 Using image tag: $TAG"

export REGISTRY=$REGISTRY
export TAG=$TAG

# Full image name
IMAGE="$REGISTRY/sms-gw:$TAG"

# Pull the latest image with the given tag
echo "🐳 Pulling docker image: $IMAGE"
docker pull $IMAGE

# Stop and remove existing container
echo "🛑 Stopping existing container..."
docker compose down || true

# Update docker-compose to use the specific image tag and registry
echo "🚀 Starting container with image: $IMAGE"
TAG=$TAG REGISTRY=$REGISTRY docker compose up -d

# Wait for container to start and check health
echo "⏳ Waiting for container to start..."
sleep 5

# Check if container is running
if docker compose ps | grep -q "Up"; then
  echo "✅ Container is running successfully"
else
  echo "❌ Container failed to start"
  docker compose logs
  exit 1
fi

# Cleanup old images
echo "🧹 Cleaning up unused docker images..."
docker image prune -f

# Optional: Remove unused images (more aggressive cleanup)
# docker image prune -a -f

echo "✅ Deployment complete!"
echo "📊 Image: $IMAGE"
echo "🌐 Registry: $REGISTRY"