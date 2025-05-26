#!/bin/bash

# Development setup script for Dapr microservices on Kind cluster
set -e
WORKSPACE_PATH=$(pwd)

echo "🚀 Setting up Dapr microservices development environment on Kind cluster..."

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    echo "❌ UV is not installed. Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source ~/.bashrc
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Kind is not installed. Installing Kind..."
    # For macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install kind
        else
            echo "Please install Homebrew first or install Kind manually: https://kind.sigs.k8s.io/docs/user/quick-start/"
            exit 1
        fi
    else
        # For Linux
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Installing kubectl..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
fi

# Check if Dapr CLI is installed
if ! command -v dapr &> /dev/null; then
    echo "❌ Dapr CLI is not installed. Please install it first:"
    echo "   https://docs.dapr.io/getting-started/install-dapr-cli/"
    exit 1
fi

# Generate Kind cluster configuration with correct paths
echo "📝 Generating Kind cluster configuration..."
./scripts/generate-kind-config.sh

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "dapr-dev"; then
    echo "🔧 Creating Kind cluster..."
    kind create cluster --config kind-cluster.yaml
    echo "✅ Kind cluster created"
else
    echo "✅ Kind cluster 'dapr-dev' already exists"
fi

# Set kubectl context to the Kind cluster
kubectl cluster-info --context kind-dapr-dev

# Initialize Dapr on the Kind cluster
echo "🔧 Initializing Dapr on Kind cluster..."
dapr init -k --dev

# Wait for Dapr to be ready
echo "⏳ Waiting for Dapr to be ready..."
kubectl wait --for=condition=ready pod -l app=dapr-operator -n dapr-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=dapr-sidecar-injector -n dapr-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=dapr-placement-server -n dapr-system --timeout=300s

# Setup micro-one
echo "📦 Setting up micro-one..."
cd micro-one
uv sync
echo "✅ micro-one dependencies installed"
cd ..

# Setup micro-two
echo "📦 Setting up micro-two..."
cd micro-two
uv sync
echo "✅ micro-two dependencies installed"
cd ..

echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Cluster info:"
kubectl get nodes
echo ""
echo "🔧 Dapr status:"
kubectl get pods -n dapr-system
echo ""
echo "Next steps:"
echo "1. Build and load images: ./scripts/build-images.sh"
echo "2. Deploy services to Kind: ./scripts/run-local.sh"
echo "3. Test the services using: ./scripts/test-services.sh"
echo "4. View the API docs at:"
echo "   - Micro-one: http://localhost:8001/docs"
echo "   - Micro-two: http://localhost:8002/docs"
echo ""
echo "💡 Useful commands:"
echo "   - View cluster: kubectl get all"
echo "   - Delete cluster: kind delete cluster --name dapr-dev"
echo "   - Cluster logs: kubectl logs -n dapr-system -l app=dapr-operator" 