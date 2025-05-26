#!/bin/bash

# Script to generate Kind cluster configuration with correct paths
set -e

# Get the absolute path of the current directory
WORKSPACE_PATH=$(pwd)

echo "📝 Generating Kind cluster configuration..."
echo "🗂️  Workspace path: $WORKSPACE_PATH"

# Generate the Kind cluster configuration
cat > kind-cluster.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dapr-dev
networking:
  # WARNING: It is _strongly_ recommended that you keep this the default
  # (127.0.0.1) for security reasons. However it is possible to change this.
  apiServerAddress: "127.0.0.1"
  # By default the API server listens on a random open port.
  # You may choose a specific port but probably don't need to in most cases.
  # Using a random port makes it easier to spin up multiple clusters.
nodes:
- role: control-plane
  extraMounts:
  - hostPath: $WORKSPACE_PATH
    containerPath: /workspace
EOF

echo "✅ Kind cluster configuration generated at kind-cluster.yaml"
echo "📁 Source code will be mounted from:"
echo "   - $WORKSPACE_PATH/micro-one -> /workspace/micro-one"
echo "   - $WORKSPACE_PATH/micro-two -> /workspace/micro-two" 