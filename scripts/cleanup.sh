#!/bin/bash

# Script to cleanup Kind cluster and deployments
set -e

echo "🧹 Cleanup script for Dapr microservices on Kind cluster"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  deployments    Remove only the microservice deployments"
    echo "  cluster        Delete the entire Kind cluster"
    echo "  all            Remove deployments and delete cluster"
    echo "  help           Show this help message"
    echo ""
}

# Check if Kind cluster exists
check_cluster() {
    if ! kind get clusters | grep -q "dapr-dev"; then
        echo "❌ Kind cluster 'dapr-dev' not found."
        return 1
    fi
    return 0
}

# Cleanup deployments only
cleanup_deployments() {
    echo "🗑️  Removing microservice deployments..."
    
    if check_cluster; then
        kubectl config use-context kind-dapr-dev
        
        # Remove microservice deployments (try both production and dev versions)
        if kubectl get deployment micro-one &> /dev/null; then
            # Try to delete production deployment first
            kubectl delete -f micro-one/deploy/deployment.yaml --ignore-not-found=true
            kubectl delete -f micro-one/deploy/service.yaml --ignore-not-found=true
            kubectl delete -f micro-one/deploy/dapr-component.yaml --ignore-not-found=true
            
            # Try to delete development deployment
            kubectl delete -f micro-one/deploy/deployment-dev.yaml --ignore-not-found=true
            
            echo "✅ micro-one deployment removed"
        fi
        
        if kubectl get deployment micro-two &> /dev/null; then
            # Try to delete production deployment first
            kubectl delete -f micro-two/deploy/deployment.yaml --ignore-not-found=true
            kubectl delete -f micro-two/deploy/service.yaml --ignore-not-found=true
            kubectl delete -f micro-two/deploy/dapr-component.yaml --ignore-not-found=true
            
            # Try to delete development deployment
            kubectl delete -f micro-two/deploy/deployment-dev.yaml --ignore-not-found=true
            
            echo "✅ micro-two deployment removed"
        fi
        
        # Remove Redis if it exists
        if kubectl get deployment redis-master &> /dev/null; then
            kubectl delete deployment redis-master
            kubectl delete service redis-master
            echo "✅ Redis removed"
        fi
        
        echo "🎉 All deployments cleaned up!"
    fi
}

# Delete entire cluster
cleanup_cluster() {
    echo "🗑️  Deleting Kind cluster..."
    
    if check_cluster; then
        kind delete cluster --name dapr-dev
        echo "✅ Kind cluster 'dapr-dev' deleted"
    fi
}

# Main logic
case "${1:-help}" in
    "deployments")
        cleanup_deployments
        ;;
    "cluster")
        cleanup_cluster
        ;;
    "all")
        cleanup_deployments
        cleanup_cluster
        ;;
    "help"|*)
        show_usage
        ;;
esac 