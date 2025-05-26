#!/bin/bash

# Script to deploy microservices to Kubernetes
set -e

echo "🚀 Deploying Dapr microservices to Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Dapr is installed on Kubernetes
if ! kubectl get namespace dapr-system &> /dev/null; then
    echo "❌ Dapr is not installed on Kubernetes. Please run 'dapr init -k' first."
    exit 1
fi

# Deploy micro-two first (receiver)
echo "📡 Deploying micro-two (receiver service)..."
kubectl apply -f micro-two/deploy/
echo "✅ micro-two deployed"

# Wait a bit for micro-two to be ready
echo "⏳ Waiting for micro-two to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-two --timeout=300s

# Deploy micro-one (sender)
echo "📤 Deploying micro-one (sender service)..."
kubectl apply -f micro-one/deploy/
echo "✅ micro-one deployed"

# Wait for micro-one to be ready
echo "⏳ Waiting for micro-one to be ready..."
kubectl wait --for=condition=ready pod -l app=micro-one --timeout=300s

echo "🎉 All services deployed successfully!"
echo ""
echo "📋 Deployment status:"
kubectl get pods -l app=micro-one -o wide
kubectl get pods -l app=micro-two -o wide
echo ""
echo "🌐 Services:"
kubectl get services
echo ""
echo "💡 To test the services:"
echo "1. Port forward: kubectl port-forward service/micro-one 8001:80"
echo "2. Test: curl -X POST http://localhost:8001/send-message -H 'Content-Type: application/json' -d '{\"message\": \"Hello from K8s!\"}'"
echo "3. Check logs: kubectl logs -l app=micro-one -f" 