#!/bin/bash

# Script to deploy microservices to Kind cluster in development mode with hot reloading
set -e
WORKSPACE_PATH=$(pwd)
echo "Current workspace path: $WORKSPACE_PATH"
echo "🚀 Deploying Dapr microservices to Kind cluster in DEVELOPMENT mode..."
echo "📁 Source code will be mounted for hot reloading"

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

# Deploy Redis for state store and pub/sub (if not already deployed)
if ! kubectl get deployment redis-master &> /dev/null; then
    echo "📦 Deploying Redis..."
    kubectl create deployment redis-master --image=redis:7-alpine
    kubectl expose deployment redis-master --port=6379 --target-port=6379
    kubectl wait --for=condition=available deployment/redis-master --timeout=300s
    echo "✅ Redis deployed"
fi

# Deploy Dapr components first
echo "🔧 Deploying Dapr components..."
kubectl apply -f micro-one/deploy/dapr-component.yaml
kubectl apply -f micro-two/deploy/dapr-component.yaml
echo "✅ Dapr components deployed"

# Deploy services (using regular service definitions)
echo "🌐 Deploying services..."
kubectl apply -f micro-two/deploy/deployment-dev.yaml
kubectl apply -f micro-one/deploy/deployment-dev.yaml
echo "✅ Services deployed"

# Deploy micro-two first (receiver) in development mode
echo "📡 Deploying micro-two (receiver service) in development mode..."
kubectl apply -f micro-two/deploy/deployment-dev.yaml
echo "✅ micro-two deployed in development mode"

# Wait for micro-two to be ready
echo "⏳ Waiting for micro-two to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-two --timeout=600s

# Deploy micro-one (sender) in development mode
echo "📤 Deploying micro-one (sender service) in development mode..."
kubectl apply -f micro-one/deploy/deployment-dev.yaml
echo "✅ micro-one deployed in development mode"

# Wait for micro-one to be ready
echo "⏳ Waiting for micro-one to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-one --timeout=600s

echo "🎉 All services deployed successfully to Kind cluster in DEVELOPMENT mode!"
echo ""
echo "🔥 Hot reloading is ENABLED - changes to source code will automatically restart the services"
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
echo "💡 Development commands:"
echo "   - View logs: kubectl logs -l app=micro-one -f"
echo "   - Watch pod restarts: kubectl get pods -w"
echo "   - Exec into pod: kubectl exec -it deployment/micro-one -- bash"
echo "   - View all resources: kubectl get all"
echo ""
echo "🔧 To make changes:"
echo "   1. Edit files in micro-one/ or micro-two/ directories"
echo "   2. Changes will be automatically detected and services restarted"
echo "   3. Check logs to see restart: kubectl logs -l app=micro-one -f" 