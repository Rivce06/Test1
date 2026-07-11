# DevOps Portfolio: Kubernetes and Helm Platform

This repository is designed as a production-like DevOps portfolio project that demonstrates a modern deployment platform for a MERN-style application.

## Architecture

The platform consists of:
- React frontend deployed as a Kubernetes Deployment
- Node.js backend deployed as a Kubernetes Deployment
- MongoDB deployed as a StatefulSet for durable, stateful data storage
- Internal Services for communication between tiers
- Ingress for external traffic routing
- ConfigMaps and Secrets for configuration and sensitive values

## Local Docker Compose Execution

For the containerized local development path, use the Docker Compose entry point in [app/docker-mern-nginx](app/docker-mern-nginx):

```bash
cp app/docker-mern-nginx/.env.example app/docker-mern-nginx/.env
docker compose -f app/docker-mern-nginx/docker-compose.yml up --build
```

The UI is then available at http://127.0.0.1:8888 and the API at http://127.0.0.1:6868.

## Kubernetes and Helm Structure

The application deployment is fully managed through Helm. The chart is located in:
- [helm/mern-app](helm/mern-app)

The chart includes:
- Frontend Deployment and Service
- Backend Deployment and Service
- MongoDB StatefulSet and Service
- ConfigMap and Secret resources
- Ingress definition

Environment-specific values are provided through:
- [helm/mern-app/values.yaml](helm/mern-app/values.yaml)
- [helm/mern-app/values-dev.yaml](helm/mern-app/values-dev.yaml)
- [helm/mern-app/values-prod.yaml](helm/mern-app/values-prod.yaml)

## Helm Workflow

Typical workflow:

```bash
helm lint helm/mern-app -f helm/mern-app/values-dev.yaml
helm upgrade --install mern-app helm/mern-app -f helm/mern-app/values-dev.yaml -n dev --create-namespace
```

For production:

```bash
helm upgrade --install mern-app helm/mern-app -f helm/mern-app/values-prod.yaml -n production --create-namespace
```

## Kubernetes Components

- Deployments: frontend and backend
- StatefulSet: MongoDB
- Services: internal discovery and routing
- Ingress: public access for the application and API routes
- ConfigMap: non-sensitive runtime configuration
- Secret: credentials and tokens

## CI/CD Flow

The repository includes a GitLab CI pipeline in [.gitlab-ci.yml](.gitlab-ci.yml) that is structured for:
- chart validation
- image build preparation
- image push preparation
- Helm deployment with `helm upgrade --install`

This simulates a real delivery pipeline from source to cluster deployment.

## Observability Architecture

Monitoring is intentionally separated from the application chart and is placed under [monitoring](monitoring). This reflects a production pattern where platform observability is managed independently with tools such as:
- kube-prometheus-stack for metrics and dashboards
- Loki for centralized logging

## Infrastructure as Code

Terraform scaffolding is available in [terraform](terraform) for future cloud deployment automation.
