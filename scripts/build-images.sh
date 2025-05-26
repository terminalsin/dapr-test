#!/bin/bash

# Script to build Docker images for both microservices
set -e

echo "🐳 Building Docker images for Dapr microservices..."

# Build micro-one image
echo "📦 Building micro-one image..."
cd micro-one
docker build -t micro-one:latest .
echo "✅ micro-one image built successfully"
cd ..

# Build micro-two image
echo "📦 Building micro-two image..."
cd micro-two
docker build -t micro-two:latest .
echo "✅ micro-two image built successfully"
cd ..

echo "🎉 All Docker images built successfully!"
echo ""
echo "📋 Built images:"
docker images | grep -E "(micro-one|micro-two)"
echo ""

# Load images into Kind cluster if it exists
if kind get clusters | grep -q "dapr-dev"; then
    echo "📦 Loading images into Kind cluster..."
    kind load docker-image micro-one:latest --name dapr-dev
    kind load docker-image micro-two:latest --name dapr-dev
    echo "✅ Images loaded into Kind cluster"
    echo ""
fi

echo "Next steps:"
echo "1. Deploy to Kind cluster: ./scripts/run-local.sh"
echo "2. Or deploy to remote Kubernetes: ./scripts/deploy-k8s.sh" 