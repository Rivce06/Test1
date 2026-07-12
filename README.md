# Test1: MERN Infrastructure Engineering Journey

This repository documents the engineering journey for deploying a MERN-style application infrastructure on Kubernetes. It is not a generic template repo; it is the product of incremental validation, debugging, and architecture decisions made from the first Kubernetes experiment to the current observability-enabled proof of concept.

## Why this project exists

The initial goal was simple: deploy a MERN application into Kubernetes and prove the platform infrastructure first. The focus was intentionally on the infrastructure, not on the application source code.

To separate concerns, the first working step was to use published Docker Hub images from the original project:

- Backend: `samintelli/idurar-backend`
- Frontend: `samintelli/idurar-frontend`

This decision was deliberate. Using known-good container images allowed the project to validate Kubernetes, Helm, Services, ConfigMaps, Secrets, and Ingress without waiting for application image builds or repository integration.

## Repository structure and responsibility separation

The repository was reorganized early in the project to reflect responsibility domains:

- `helm/` — application deployment chart and templates
- `monitoring/` — observability platform artifacts
- `terraform/` — cloud infrastructure scaffolding and namespace provisioning

This separation was made intentionally to keep application delivery, monitoring, and infrastructure automation distinct.

## What is actually present in this repo

- `helm/mern-app/Chart.yaml` — manual application chart metadata
- `helm/mern-app/templates/` — custom Deployment, Service, ConfigMap, Secret, and Ingress manifests
- `helm/mern-app/values.yaml` — development baseline values using Docker Hub images
- `monitoring/README.md` — observability stack intent
- `terraform/main.tf` — Kubernetes provider and namespace scaffolding
- `.gitlab-ci.yml` — a GitLab CI placeholder pipeline for future automation
- `.env.example` — local development configuration with temporary values

## Helm chart evolution

The Helm chart was built manually rather than adapting an existing application chart. This gave full control over each template and made incremental validation easier.

Templates created and improved progressively:

- `backend-deployment.yaml`
- `frontend-deployment.yaml`
- `backend-service.yaml`
- `frontend-service.yaml`
- `frontend-service.yaml`
- `configmap.yaml`
- `secret.yaml`
- `ingress.yaml`

Each template was added intentionally as the project moved from a rough proof of concept to a deployable platform.

### Why manual templates?

A manual chart meant the project could document and debug each layer:

- Deployment shape and container environment
- Service discovery and ports
- Shared runtime configuration via ConfigMap
- Sensitive values via Secret
- External routing via Ingress

This grounding was essential before layering in cloud-native production concerns.

## MongoDB architecture: from StatefulSet to Atlas

The original plan was to run MongoDB inside Kubernetes, likely with a `StatefulSet` for durable storage. That is a reasonable first idea for a full in-cluster stack.

However, the architecture changed when the project adopted MongoDB Atlas instead of an in-cluster database.

### Why MongoDB Atlas?

- Simplified storage and database provisioning
- Avoids managing persistent volume claims and replica set lifecycle within the cluster
- Reflects how many companies deploy production databases
- Decouples stateful storage from the application platform

This was a pragmatic engineering decision: validate the Kubernetes delivery platform first, then connect the backend to a managed database service.

## The ConfigMap / Secret debugging story

A major early issue was secret rendering. The Helm `Secret` template was present, but the generated manifest contained:

```yaml
stringData:
null
```

That meant the backend never received the `DATABASE` environment variable and failed at runtime.

### How the issue was diagnosed

The problem was found through a series of validation commands:

- `helm template helm/mern-app -f helm/mern-app/values-dev.yaml`
  - Why: to inspect rendered Kubernetes manifests before applying anything.
  - What it showed: the secret manifest was wrong and `stringData` was empty/null.

- `helm get manifest mern-app -n dev`
  - Why: after a release was installed, this confirms what Helm actually deployed.
  - What it showed: the live manifest still had the secret issue.

- `helm get values mern-app -n dev`
  - Why: verify the values that were passed to the release and confirm they contained the expected secret fields.
  - What it showed: the values shape was not aligned with the `secret.yaml` template.

- `kubectl get secret mern-app-secret -n dev -o yaml`
  - Why: inspect the actual Kubernetes Secret object and compare it with expected data.
  - What it showed: the rendered secret object did not contain the expected `DATABASE` entry.

### Root cause and fix

The root cause was the `values.yaml` structure and the template assumptions around `secret.data`. Once the values were corrected and the secret template rendered actual key/value pairs, the backend environment injection began working.

## Chronological deployment issues and debugging steps

This project was developed through repeated validation cycles. The sequence below records the real problems encountered and the tools used to resolve them.

### 1. Initial Helm/YAML mistakes

Problems:
- invalid YAML syntax in templates
- incorrect indentation in generated manifests
- mismatched field names in `values.yaml`

Why this matters:
- Helm fails fast when templates are syntactically invalid
- Kubernetes refuses manifests with malformed indentation or invalid API fields

Tools used:
- `helm lint helm/mern-app -f helm/mern-app/values-dev.yaml` to catch chart-level issues
- `helm template ...` to preview rendered output and catch YAML formatting errors

### 2. Cluster availability issues

Problems:
- Minikube cluster unavailable
- Helm reporting Kubernetes cluster unreachable

Why this matters:
- Helm and kubectl require a healthy kubeconfig context and reachable API server
- Infrastructure validation cannot proceed without an active cluster

Tools used:
- `minikube status` to confirm the local cluster state
- `kubectl cluster-info` and `kubectl get nodes` to verify connectivity
- `helm version` to confirm Helm could reach the cluster

### 3. CrashLoopBackOff on backend pods

Problems:
- backend pod restarts immediately
- backend failing to connect to MongoDB
- missing `DATABASE` configuration caused startup failure

Why this matters:
- `CrashLoopBackOff` is a symptom, not a cause. Inspecting logs is required.

Tools used:
- `kubectl get pods -n dev` to identify failing pods
- `kubectl describe pod <pod-name> -n dev` to inspect events and readiness probe failures
- `kubectl logs deployment/<release>-backend -n dev` to read the backend container startup logs

What it revealed:
- the backend could not resolve or authenticate to MongoDB Atlas
- environment variables were not populated correctly from the Secret

### 4. Fixing secrets and database connectivity

Problems:
- backend had `DATABASE` undefined
- Atlas connection string was not injected correctly

Why this matters:
- application startup depends on runtime environment configuration
- managed database access must be validated after platform deployment

Tools used:
- `kubectl get secret mern-app-secret -n dev -o yaml`
- `helm get manifest mern-app -n dev`
- `helm get values mern-app -n dev`

What it revealed:
- the Secret resource was rendered incorrectly
- the values file needed a corrected key structure for `secret.data`

### 5. Application and database validation

Once the backend connected successfully to MongoDB Atlas, the frontend deployed and application runtime behavior could be validated.

Problems observed:
- initial authentication failed
- the application had not yet created the expected Atlas collections

Why this matters:
- runtime validation confirms the end-to-end path from browser to API to database
- Atlas collection creation demonstrates that the backend is authorized and able to write data

Validation steps:
- open the application UI through the cluster ingress or service port
- attempt login or register flows
- inspect MongoDB Atlas directly for created collections and administrative accounts

Outcome:
- the application eventually created its collections inside Atlas
- the administrator account was located in Atlas
- the application became fully operational from end to end

## Observability stage

The monitoring stack was already installed prior to full application deployment. Once the MERN application landed successfully, Grafana was verified and dashboards became available. This marked the beginning of the observability stage.

The `monitoring/` directory represents the intended separation between application deployment and platform observability. In a mature platform, monitoring is managed independently from the application chart.

## Development workflow

This project follows a GitFlow-inspired workflow:

- `feature` branch — current infrastructure work and validation
- `main` branch — reserved for stable, validated infrastructure

Nothing should be merged into `main` until every infrastructure component has been validated.

### Future intended flow

1. `feature` branch
2. infrastructure validation in local / dev cluster
3. GitLab CI/CD pipeline validation
4. ArgoCD deployment automation
5. merge into `main`
6. cloud deployment on AWS or GCP

## Current status

### Completed

- Docker images selected from Docker Hub for infrastructure validation
- Helm chart manually created
- Backend and frontend Deployments built
- Backend and frontend Services configured
- ConfigMap introduced for runtime configuration
- Secret template introduced for sensitive data
- Ingress manifest created for external routing
- MongoDB Atlas integration adopted
- Application deployed successfully to Kubernetes
- Prometheus and Grafana observability stack validated

### In progress

- Loki centralized logging integration
- additional observability validation

### Future work

- GitLab CI/CD implementation and pipeline enforcement
- Docker image automation for frontend/backend builds
- ArgoCD deployment automation and GitOps promotion
- Terraform-based cloud deployment
- AWS or GCP production deployment targeting managed platform services
- Vault or Secret Manager integration for runtime secrets
- production hardening and security validation

## Security and credentials note

During development, several credentials were temporarily stored in plain text inside development configuration files such as `.env.example` and local chart values. This was done only to simplify local testing and infrastructure debugging.

This temporary approach is acceptable only for local development and educational validation. It is not the intended production design.

Once the infrastructure has been validated, the following secrets must be rotated and moved to a secure secret management solution such as HashiCorp Vault, AWS Secrets Manager, or Google Secret Manager:

- MongoDB credentials
- Grafana credentials
- JWT secrets
- application runtime secrets

## How to validate the current chart

The current application Helm chart is the central artifact for deployment validation.

Example validation commands:

```bash
helm lint helm/mern-app -f helm/mern-app/values.yaml
helm template helm/mern-app -f helm/mern-app/values.yaml
helm upgrade --install mern-app helm/mern-app -f helm/mern-app/values.yaml -n dev --create-namespace
```

If the release is installed, use these commands to inspect the deployed state:

```bash
helm get manifest mern-app -n dev
helm get values mern-app -n dev
kubectl get secret mern-app-secret -n dev -o yaml
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
kubectl logs deployment/mern-app-backend -n dev
```

These are the same tools used during the actual development cycle to diagnose and fix the issues described above.

## What this README is meant to convey

This document is not just architecture documentation. It records the engineering journey, the decisions to defer application image ownership until infrastructure validation was complete, the move from in-cluster MongoDB to Atlas, the exact debugging commands that exposed configuration issues, and the roadmap toward a production-ready cloud deployment.
