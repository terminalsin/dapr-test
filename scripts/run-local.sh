#!/bin/bash

# Script to deploy microservices to Kind cluster for local development
set -e
WORKSPACE_PATH=$(pwd)
echo "Current workspace path: $WORKSPACE_PATH"
echo "🚀 Deploying Dapr microservices to Kind cluster..."

# Check if Kind cluster exists
if ! kind get clusters | grep -q "dapr-dev"; then
    echo "❌ Kind cluster 'dapr-dev' not found. Please run ./scripts/dev-setup.sh first."
    exit 1
fi

# Set kubectl context to Kind cluster
kubectl config use-context kind-dapr-dev

# Check if Dapr is installed
if ! kubectl get namespace dapr-system &> /dev/null; then
    echo "❌ Dapr is not installed on the cluster. Please run ./scripts/dev-setup.sh first."
    exit 1
fi

# Check if images exist in Kind cluster
echo "🔍 Checking if Docker images are loaded in Kind cluster..."
if ! docker exec dapr-dev-control-plane crictl images | grep -q "micro-one"; then
    echo "❌ micro-one image not found in Kind cluster. Please run ./scripts/build-images.sh first."
    exit 1
fi

if ! docker exec dapr-dev-control-plane crictl images | grep -q "micro-two"; then
    echo "❌ micro-two image not found in Kind cluster. Please run ./scripts/build-images.sh first."
    exit 1
fi

# Deploy Redis for state store and pub/sub (if not already deployed)
if ! kubectl get deployment redis-master &> /dev/null; then
    echo "📦 Deploying Redis..."
    kubectl create deployment redis-master --image=redis:7-alpine
    kubectl expose deployment redis-master --port=6379 --target-port=6379
    kubectl wait --for=condition=available deployment/redis-master --timeout=300s
    echo "✅ Redis deployed"
fi

# Deploy micro-two first (receiver)
echo "📡 Deploying micro-two (receiver service)..."
sed "s|PWD_PLACEHOLDER|$WORKSPACE_PATH|g" micro-two/deploy/deployment-dev.yaml | kubectl apply -f -
echo "✅ micro-two deployed"

# Wait for micro-two to be ready
echo "⏳ Waiting for micro-two to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-two --timeout=300s

# Deploy micro-one (sender)
echo "📤 Deploying micro-one (sender service)..."
sed "s|PWD_PLACEHOLDER|$WORKSPACE_PATH|g" micro-one/deploy/deployment-dev.yaml | kubectl apply -f -
echo "✅ micro-one deployed"

# Wait for micro-one to be ready
echo "⏳ Waiting for micro-one to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-one --timeout=300s

echo "🎉 All services deployed successfully to Kind cluster!"
echo ""
echo "📋 Deployment status:"
kubectl get pods -o wide
echo ""
echo "🌐 Services:"
kubectl get services
echo ""
echo "🌐 Service URLs (via NodePort):"
echo "   - Micro-one: http://localhost:8001"
echo "   - Micro-two: http://localhost:8002"
echo "   - Micro-one docs: http://localhost:8001/docs"
echo "   - Micro-two docs: http://localhost:8002/docs"
echo ""
echo "💡 Useful commands:"
echo "   - View logs: kubectl logs -l app=micro-one -f"
echo "   - View all resources: kubectl get all"
echo "   - Delete deployments: kubectl delete -f micro-one/deploy/ -f micro-two/deploy/"
echo "   - Restart deployment: kubectl rollout restart deployment/micro-one" 