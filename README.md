# Dapr Microservices Demo

This project demonstrates two Python microservices (`micro-one` and `micro-two`) built with Dapr, FastAPI, and modern Python tooling, running on a local Kind (Kubernetes in Docker) cluster.

## Architecture

- **micro-one**: A service that sends messages to micro-two
- **micro-two**: A service that receives and processes messages from micro-one
- **Dapr**: Provides service-to-service communication, state management, and pub/sub
- **FastAPI + Uvicorn**: High-performance async web framework
- **UV**: Fast Python package manager and project manager
- **Kind**: Local Kubernetes cluster for development
- **Redis**: State store and pub/sub backend

## Prerequisites

- Python 3.11+
- [UV](https://docs.astral.sh/uv/) - `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/)
- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (will be auto-installed on macOS with Homebrew)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (will be auto-installed on macOS with Homebrew)

## Quick Start

### Option 1: Development Mode with Hot Reload (Recommended)

```bash
# Complete setup and deploy in development mode
./scripts/dev-workflow.sh setup
./scripts/dev-workflow.sh dev

# Test the services
./scripts/dev-workflow.sh test
```

### Option 2: Production Mode (with Docker images)

```bash
# Complete setup, build, and deploy
./scripts/dev-workflow.sh setup
./scripts/dev-workflow.sh build
./scripts/dev-workflow.sh deploy

# Test the services
./scripts/dev-workflow.sh test
```

### Option 3: Step by Step (Development Mode)

```bash
# 1. Setup Kind cluster and Dapr
./scripts/dev-setup.sh

# 2. Deploy services in development mode (no build needed)
./scripts/run-dev.sh

# 3. Test the services
./scripts/test-services.sh
```

### Option 4: Step by Step (Production Mode)

```bash
# 1. Setup Kind cluster and Dapr
./scripts/dev-setup.sh

# 2. Build and load Docker images
./scripts/build-images.sh

# 3. Deploy services to Kind cluster
./scripts/run-local.sh

# 4. Test the services
./scripts/test-services.sh
```

### 3. Test the Services Manually

```bash
# Send a message from micro-one to micro-two
curl -X POST "http://localhost:8001/send-message" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Kind cluster!"}'

# Check micro-one health
curl http://localhost:8001/health

# Check micro-two health
curl http://localhost:8002/health
```

## Development Workflow

### Available Scripts

```bash
# Development workflow helper
./scripts/dev-workflow.sh [OPTION]

# Options:
#   setup          Complete setup (cluster + dependencies)
#   build          Build and load Docker images
#   deploy         Deploy services to cluster (production mode)
#   dev            Deploy services in development mode (hot reload)
#   test           Run tests against deployed services
#   logs           Show logs from all services
#   status         Show cluster and deployment status
#   restart        Restart all deployments
#   redeploy       Build, load images, and redeploy
#   cleanup        Cleanup deployments
#   reset          Complete reset (cleanup + setup + deploy)
```

### Individual Scripts

```bash
# Setup Kind cluster and Dapr
./scripts/dev-setup.sh

# Build and load Docker images
./scripts/build-images.sh

# Deploy to Kind cluster (production mode)
./scripts/run-local.sh

# Deploy to Kind cluster (development mode with hot reload)
./scripts/run-dev.sh

# Test services
./scripts/test-services.sh

# Cleanup
./scripts/cleanup.sh [deployments|cluster|all]
```

### Remote Kubernetes Deployment

For deploying to a remote Kubernetes cluster:

```bash
# Ensure kubectl is configured for your cluster
kubectl config current-context

# Deploy services
./scripts/deploy-k8s.sh
```

## Development

### Development Mode Features

The project supports two deployment modes:

**Development Mode** (`./scripts/dev-workflow.sh dev` or `./scripts/run-dev.sh`):
- ✅ **Hot Reloading**: Changes to source code automatically restart services
- ✅ **No Build Required**: Uses Python base image and installs dependencies at runtime
- ✅ **Source Code Mounting**: Local files are mounted into containers
- ✅ **Debug Logging**: Enhanced logging for development
- ✅ **Fast Iteration**: Make changes and see results immediately

**Production Mode** (`./scripts/dev-workflow.sh deploy` or `./scripts/run-local.sh`):
- ✅ **Optimized Images**: Uses pre-built Docker images
- ✅ **Production Ready**: Mimics production deployment
- ✅ **Multiple Replicas**: Can scale to multiple instances
- ✅ **Resource Limits**: Proper resource constraints

### Technology Stack

Each microservice uses:
- **UV** for dependency management and virtual environments
- **FastAPI** for the web framework
- **Uvicorn** as the ASGI server
- **Structured logging** with Python's logging module
- **Dapr SDK** for service communication

### Adding Dependencies

```bash
cd micro-one  # or micro-two
uv add package-name
```

### Making Changes in Development Mode

When using development mode, you can edit files directly and see changes immediately:

```bash
# 1. Deploy in development mode
./scripts/dev-workflow.sh dev

# 2. Edit any Python file in micro-one/ or micro-two/
# For example, edit micro-one/app/main.py

# 3. Watch the logs to see the service restart
kubectl logs -l app=micro-one -f

# 4. Test your changes
curl http://localhost:8001/health
```

### Running Tests

```bash
cd micro-one  # or micro-two
uv run pytest
```

## Project Structure

```
.
├── README.md
├── kind-cluster.yaml              # Kind cluster configuration
├── scripts/
│   ├── dev-setup.sh              # Setup Kind cluster and Dapr
│   ├── generate-kind-config.sh   # Generate Kind config with correct paths
│   ├── build-images.sh           # Build and load Docker images
│   ├── run-local.sh              # Deploy to Kind cluster (production)
│   ├── run-dev.sh                # Deploy to Kind cluster (development)
│   ├── test-services.sh          # Test deployed services
│   ├── deploy-k8s.sh             # Deploy to remote Kubernetes
│   ├── cleanup.sh                # Cleanup deployments/cluster
│   └── dev-workflow.sh           # Complete workflow helper
├── micro-one/
│   ├── pyproject.toml
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   └── services/
│   ├── deploy/
│   │   ├── deployment.yaml       # Production deployment
│   │   ├── deployment-dev.yaml   # Development deployment (hot reload)
│   │   ├── service.yaml
│   │   └── dapr-component.yaml
│   └── tests/
└── micro-two/
    ├── pyproject.toml
    ├── app/
    │   ├── __init__.py
    │   ├── main.py
    │   └── services/
    ├── deploy/
    │   ├── deployment.yaml       # Production deployment
    │   ├── deployment-dev.yaml   # Development deployment (hot reload)
    │   ├── service.yaml
    │   └── dapr-component.yaml
    └── tests/
```

## Monitoring and Observability

- Logs are structured and include correlation IDs
- Health endpoints available at `/health`
- Dapr provides distributed tracing out of the box
- Metrics available through Dapr sidecars
- Access services via NodePort on localhost:8001 and localhost:8002
- View logs: `kubectl logs -l app=micro-one -f`
- Dapr dashboard: `kubectl port-forward -n dapr-system svc/dapr-dashboard 8080:8080`

## Troubleshooting

### Common Issues

1. **Kind cluster not found**: Run `./scripts/dev-setup.sh`
2. **Images not found**: Run `./scripts/build-images.sh`
3. **Services not responding**: Check with `./scripts/dev-workflow.sh status`
4. **Port conflicts**: Ensure ports 8001, 8002 are available

### Useful Commands

```bash
# Check cluster status
./scripts/dev-workflow.sh status

# View logs
./scripts/dev-workflow.sh logs

# Restart services
./scripts/dev-workflow.sh restart

# Complete reset
./scripts/dev-workflow.sh reset

# Manual kubectl commands
kubectl get all
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c micro-one
``` 