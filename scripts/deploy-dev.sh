#!/bin/bash

# Get the current working directory
WORKSPACE_PATH=$(pwd)

echo "🚀 Deploying microservices with workspace path: $WORKSPACE_PATH"

# Deploy micro-one
echo "📦 Deploying micro-one..."
sed "s|PWD_PLACEHOLDER|$WORKSPACE_PATH|g" micro-one/deploy/deployment-dev.yaml | kubectl apply -f -

# Deploy micro-two
echo "📦 Deploying micro-two..."
sed "s|PWD_PLACEHOLDER|$WORKSPACE_PATH|g" micro-two/deploy/deployment-dev.yaml | kubectl apply -f -

echo "✅ Deployment complete!"
echo "💡 Source code is mounted from:"
echo "   - $WORKSPACE_PATH/micro-one/src -> /app (in micro-one pod)"
echo "   - $WORKSPACE_PATH/micro-two/src -> /app (in micro-two pod)" 