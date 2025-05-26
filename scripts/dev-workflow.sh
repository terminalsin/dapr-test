#!/bin/bash

# Complete development workflow script for Kind cluster
set -e

echo "🚀 Dapr Microservices - Kind Development Workflow"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup          Complete setup (cluster + dependencies)"
    echo "  build          Build and load Docker images"
    echo "  deploy         Deploy services to cluster (production mode)"
    echo "  dev            Deploy services in development mode (hot reload)"
    echo "  test           Run tests against deployed services"
    echo "  logs           Show logs from all services"
    echo "  status         Show cluster and deployment status"
    echo "  restart        Restart all deployments"
    echo "  redeploy       Build, load images, and redeploy"
    echo "  cleanup        Cleanup deployments"
    echo "  reset          Complete reset (cleanup + setup + deploy)"
    echo "  help           Show this help message"
    echo ""
    echo "Development mode (dev) features:"
    echo "  - Source code mounted from host"
    echo "  - Hot reloading enabled"
    echo "  - Debug logging"
    echo "  - No need to rebuild images for code changes"
    echo ""
}

# Setup everything
setup() {
    echo "🔧 Running complete setup..."
    ./scripts/dev-setup.sh
}

# Deploy services (production mode)
deploy() {
    echo "🚀 Deploying services in production mode..."
    ./scripts/run-local.sh
}

# Deploy services in development mode
dev() {
    echo "🔥 Deploying services in development mode with hot reload..."
    ./scripts/run-dev.sh
}

# Run tests
test() {
    echo "🧪 Running tests..."
    ./scripts/test-services.sh
}

# Show logs
logs() {
    echo "📋 Showing service logs..."
    if kubectl get deployment micro-one &> /dev/null; then
        echo "=== Micro-one logs ==="
        kubectl logs -l app=micro-one --tail=50
        echo ""
    fi
    
    if kubectl get deployment micro-two &> /dev/null; then
        echo "=== Micro-two logs ==="
        kubectl logs -l app=micro-two --tail=50
        echo ""
    fi
}

# Show status
status() {
    echo "📊 Cluster and deployment status..."
    
    if kind get clusters | grep -q "dapr-dev"; then
        kubectl config use-context kind-dapr-dev
        echo "=== Nodes ==="
        kubectl get nodes
        echo ""
        echo "=== Pods ==="
        kubectl get pods -o wide
        echo ""
        echo "=== Services ==="
        kubectl get services
        echo ""
        echo "=== Deployments ==="
        kubectl get deployments
    else
        echo "❌ Kind cluster 'dapr-dev' not found"
    fi
}

# Restart deployments
restart() {
    echo "🔄 Restarting deployments..."
    if kubectl get deployment micro-one &> /dev/null; then
        kubectl rollout restart deployment/micro-one
        echo "✅ micro-one restarted"
    fi
    
    if kubectl get deployment micro-two &> /dev/null; then
        kubectl rollout restart deployment/micro-two
        echo "✅ micro-two restarted"
    fi
    
    echo "⏳ Waiting for rollout to complete..."
    kubectl rollout status deployment/micro-one --timeout=300s
    kubectl rollout status deployment/micro-two --timeout=300s
}

# Redeploy (build + deploy)
redeploy() {
    echo "🔄 Rebuilding and redeploying..."
    build
    
    # Delete existing deployments
    if kubectl get deployment micro-one &> /dev/null; then
        kubectl delete -f micro-one/deploy/
    fi
    
    if kubectl get deployment micro-two &> /dev/null; then
        kubectl delete -f micro-two/deploy/
    fi
    
    # Wait a bit for cleanup
    sleep 5
    
    # Redeploy
    deploy
}

# Cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    ./scripts/cleanup.sh deployments
}

# Complete reset
reset() {
    echo "🔄 Complete reset..."
    ./scripts/cleanup.sh all
    setup
    build
    deploy
}

# Main logic
case "${1:-help}" in
    "setup")
        setup
        ;;
    "build")
        build
        ;;
    "deploy")
        deploy
        ;;
    "dev")
        dev
        ;;
    "test")
        test
        ;;
    "logs")
        logs
        ;;
    "status")
        status
        ;;
    "restart")
        restart
        ;;
    "redeploy")
        redeploy
        ;;
    "cleanup")
        cleanup
        ;;
    "reset")
        reset
        ;;
    "help"|*)
        show_usage
        ;;
esac 