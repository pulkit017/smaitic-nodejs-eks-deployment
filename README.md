# smaitic-nodejs-eks-deployment

## Career Objective

Deploy and run production workloads on Kubernetes. Want a DevOps role where I can own the path from commit to production. Comfortable with EKS, Helm, Jenkins and the usual monitoring stack.

## Overview

Small Node.js API, packaged as a container, deployed to AWS EKS using Helm. CI is Jenkins. Image goes to internal Artifactory after a Trivy scan. Prometheus picks up metrics from pod annotations and logs go to stdout for Filebeat to ship to ELK.

You don't need a live cluster to look at this. helm lint and helm template work on the chart as is.

## Dockerfile changes

A few things were off in the original:

- node:latest is not pinned, used node:20-alpine
- COPY . . before npm install kept invalidating the dep cache, moved package files first
- switched npm install to npm ci so it's reproducible
- single stage was shipping dev deps and build tools to runtime, made it multi-stage and only copies node_modules and dist into the final image
- was running as root, added a non root app user and chown the copied files
- added tini as entrypoint so signals and zombie procs are handled properly

## CI/CD pipeline

Jenkins declarative pipeline. Stages run in this order:

1. Checkout
2. Install deps (npm ci)
3. Test
4. Docker build
5. Trivy scan
6. Push image to Artifactory
7. Helm lint
8. Helm deploy (only on main)

Trivy fails the build on HIGH and CRITICAL only, ignoring unfixed since we dont want to block on issues that have no patch yet. Push uses the jarvis-artifactory credential (docker login from stdin). Deploy is helm upgrade --install with --atomic --wait, so a failed rollout rolls back instead of leaving the cluster in a half state.

Image tag is short-sha plus build number. No latest in deploys.

Custom variables in the Jenkinsfile use planet name prefixes (mars_, venus_, saturn_ etc.) per internal convention.

## Helm chart

```
helm/
  Chart.yaml
  values.yaml
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    ingress.yaml
    hpa.yaml
    serviceaccount.yaml
```

Notes:

- Container port is named api-web. Service targetPort and ingress backend both reference it by name not number, so changing the port number only needs a values.yaml edit.
- HPA on CPU only, 2 to 6 replicas, target 70 percent.
- Liveness is /healthz, readiness is /ready. Override in values if the app uses different paths.
- imagePullSecret jarvis-artifactory is expected to already exist in the target namespace.

## Monitoring and logging

Pod template has the prometheus scrape annotations (scrape, path, port). App should expose /metrics in prom format. Dashboards live outside this repo.

Logging is just stdout/stderr. Filebeat runs as a DaemonSet on the cluster already, so no sidecar.

## Security

- Pod runs non-root, runAsUser 1000
- Container is also non-root from the Dockerfile, tini handles init
- Trivy gate on HIGH and CRITICAL
- Registry auth via credentials('jarvis-artifactory'), never inlined in any script
- TLS terminates at the ingress with cert-manager
- Nothing sensitive in the image or chart

## Assumptions

This was built without a live cluster in mind, so a few things are assumed about the target environment:

- nginx ingress controller and cert-manager are installed
- Filebeat or some log shipper is already running cluster wide
- Prometheus is either prom-operator with annotation discovery, or kube-prometheus-stack scraping pod annotations
- The app actually exposes /healthz, /ready and /metrics
- jarvis-artifactory exists in Jenkins as a Username/Password credential and as a docker-registry Secret in the target namespace
- AWS credentials reach the Jenkins job through the usual route (instance profile, IRSA, or a separate Jenkins cred)

## Deploy steps

Local validation:

```
helm lint helm/
helm template node-api helm/ --values helm/values.yaml | kubectl apply --dry-run=client -f -
```

Manual deploy (pipeline does this on main automaticaly):

```
aws eks update-kubeconfig --name prod-eks --region ap-south-1

helm upgrade --install node-api helm/ \
  --namespace node-api --create-namespace \
  --set image.tag=<sha>-<build> \
  --atomic --wait --timeout 5m
```

Rollback if something goes wrong:

```
helm rollback node-api
```

## What I would add later

- PodDisruptionBudget once we have an SLO
- NetworkPolicy to lock egress down
- Move from annotation based scraping to a ServiceMonitor
- Structured JSON logs (pino) instead of plain text
- Multi arch image once we move to Graviton nodes
- ArgoCD for GitOps deploys, take Jenkins out of the deploy path
