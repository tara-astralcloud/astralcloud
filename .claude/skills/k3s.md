# k3s Skill

Deep knowledge for deploying, managing, and troubleshooting k3s clusters and Helm charts for AstralCloud. Covers cluster setup on Raspberry Pi (ARM64), workload management, networking, storage, and day-2 operations.

## Project Context

- **Target hardware:** Raspberry Pi (linux/arm64)
- **Kubernetes distro:** k3s — lightweight Kubernetes, bundles containerd, Flannel, CoreDNS, Traefik, local-path-provisioner
- **Platform namespace:** `astralcloud`
- **App namespaces:** one per installed app (e.g. `app-jellyfin`, `app-nextcloud`)
- **Helm charts:** core platform in `infra/helm/platform`; apps ship their own chart from their own repo
- **Image registry:** `ghcr.io/tara-astralcloud/<service>`

---

## k3s Architecture

```text
┌─────────────────────────────────────────┐
│           Raspberry Pi Cluster          │
│                                         │
│  ┌──────────────────┐                   │
│  │  Server node     │  control-plane    │
│  │  (Pi 4 / Pi 5)   │  etcd, API server │
│  └────────┬─────────┘                   │
│           │ k3s token                   │
│  ┌────────┴─────────┐                   │
│  │  Agent nodes     │  workloads        │
│  │  (Pi 4 / Pi 5)   │  containerd       │
│  └──────────────────┘                   │
└─────────────────────────────────────────┘
```

k3s differences from full Kubernetes worth knowing:

- Uses `containerd` directly — no Docker daemon
- Default CNI: Flannel (VXLAN)
- Default ingress: Traefik (can be disabled and replaced with ingress-nginx)
- Default storage: `local-path-provisioner` — single-node only, no replication
- Kubeconfig at `/etc/rancher/k3s/k3s.yaml` on the server node

---

## Cluster Installation

### Server node (control-plane)

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" sh -s - server \
  --disable traefik \
  --write-kubeconfig-mode 644
```

Disable Traefik when using ingress-nginx or when managing ingress via Helm.

Retrieve the node token (needed to join agents):

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Agent node (worker)

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" K3S_URL="https://<server-ip>:6443" K3S_TOKEN="<node-token>" sh -
```

### Kubeconfig for local access

Copy from the server node and update the server address:

```bash
scp pi@<server-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127.0.0.1/<server-ip>/g' ~/.kube/config
# On macOS use: sed -i '' 's/127.0.0.1/<server-ip>/g' ~/.kube/config
chmod 600 ~/.kube/config
```

### Verify cluster

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

---

## Helm — Core Concepts

Helm is the package manager for Kubernetes. A **chart** is a packaged application. A **release** is a deployed instance of a chart.

### Essential commands

```bash
# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for a chart
helm search repo bitnami/keycloak

# Install a chart
helm install <release-name> <chart> -n <namespace> --create-namespace -f values.yaml

# Upgrade an existing release
helm upgrade <release-name> <chart> -n <namespace> -f values.yaml

# Install or upgrade (idempotent)
helm upgrade --install <release-name> <chart> -n <namespace> --create-namespace -f values.yaml

# List releases
helm list -A

# Check release status
helm status <release-name> -n <namespace>

# View rendered templates (dry-run)
helm template <release-name> <chart> -f values.yaml

# Uninstall
helm uninstall <release-name> -n <namespace>

# Rollback to a previous revision
# First list available revisions:
helm history <release-name> -n <namespace>
# Then rollback to a specific revision number:
helm rollback <release-name> <revision> -n <namespace>
```

### values.yaml structure

```yaml
image:
  repository: ghcr.io/tara-astralcloud/file-storage
  tag: v1.2.0
  pullPolicy: IfNotPresent

replicaCount: 1

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  className: nginx
  host: files.astralcloud.local

env:
  LOG_LEVEL: info
  DATABASE_URL: "" # injected via secret

serviceAccount:
  create: true
```

---

## Platform Helm Chart

The AstralCloud platform chart lives at `infra/helm/platform/`. It bundles core services as sub-charts or Helm dependencies.

### Chart structure

```text
infra/helm/platform/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── namespace.yaml
    ├── keycloak/
    ├── file-storage/
    └── media-streaming/
```

### Chart.yaml

```yaml
apiVersion: v2
name: astralcloud
description: AstralCloud platform core
type: application
version: 0.1.0
appVersion: "0.1.0"

dependencies:
  - name: keycloak
    version: "21.0.0"
    repository: https://charts.bitnami.com/bitnami
```

After adding or changing dependencies:

```bash
helm dependency update infra/helm/platform
```

### Lint and validate before every PR

```bash
helm lint infra/helm/platform
helm template astralcloud infra/helm/platform -f infra/helm/platform/values-dev.yaml --debug > /dev/null
```

---

## Workload Patterns

### Deployment (stateless service)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-storage
  namespace: astralcloud
  labels:
    app: file-storage
    project: astralcloud
spec:
  replicas: 1
  selector:
    matchLabels:
      app: file-storage
  template:
    metadata:
      labels:
        app: file-storage
    spec:
      containers:
        - name: file-storage
          image: ghcr.io/tara-astralcloud/file-storage:v1.0.0
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          envFrom:
            - configMapRef:
                name: file-storage-config
            - secretRef:
                name: file-storage-secrets
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: file-storage
  namespace: astralcloud
spec:
  selector:
    app: file-storage
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

### Ingress (ingress-nginx)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: file-storage
  namespace: astralcloud
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: files.astralcloud.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: file-storage
                port:
                  number: 80
```

### PersistentVolumeClaim (local-path-provisioner)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: file-storage-data
  namespace: astralcloud
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
```

---

## Networking

### MetalLB — LoadBalancer on bare-metal

k3s on Pi has no cloud LoadBalancer. Install MetalLB to assign real IPs to `LoadBalancer` services:

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm upgrade --install metallb metallb/metallb --version 0.14.5 -n metallb-system --create-namespace
```

Configure an IP address pool (use IPs reserved on your router):

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: local-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: local-advert
  namespace: metallb-system
spec:
  ipAddressPools:
    - local-pool
```

### ingress-nginx

Replace k3s's default Traefik with ingress-nginx for better Helm chart compatibility:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

Create an `ingress-nginx-values.yaml`:

```yaml
controller:
  service:
    type: LoadBalancer
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
```

Then install:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.10.1 \
  -n ingress-nginx --create-namespace \
  -f ingress-nginx-values.yaml
```

---

## Storage

k3s ships `local-path-provisioner` — data lives on the node's disk. This is fine for single-node or dev. For multi-node clusters where pods can reschedule, use a distributed storage solution:

| Option       | When to use                                   |
| ------------ | --------------------------------------------- |
| `local-path` | Dev / single-node / data that won't move      |
| Longhorn     | Multi-node, replicated, Helm-installable      |
| NFS          | Shared storage when you have a NAS on the LAN |

Install Longhorn (replicated block storage for Pi clusters):

```bash
# Required on every Pi node BEFORE installing Longhorn:
sudo apt-get install -y open-iscsi
sudo systemctl enable --now iscsid

# Then install via Helm:
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm upgrade --install longhorn longhorn/longhorn \
  --version 1.6.2 \
  -n longhorn-system --create-namespace \
  --set defaultSettings.defaultReplicaCount=2
```

---

## ARM64 / Raspberry Pi Checklist

Before deploying any workload to the cluster:

- [ ] Confirm the container image has a `linux/arm64` manifest — `docker manifest inspect <image> | grep arm64`
- [ ] Check Helm chart release notes for ARM64 support (Bitnami: yes; older community charts: verify)
- [ ] Set resource `requests` and `limits` on all containers — Pi nodes have limited RAM (2–8 GB)
- [ ] Avoid `hostPort` — use `ClusterIP` + ingress or `LoadBalancer` via MetalLB
- [ ] Use `ReadWriteOnce` for PVCs with `local-path`; `ReadWriteMany` requires NFS or Longhorn
- [ ] Anti-affinity rules are important on multi-node Pi clusters — avoid scheduling all replicas on the same node

---

## Day-2 Operations

### Upgrading k3s

```bash
# On server node (check latest release at https://github.com/k3s-io/k3s/releases)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" sh -

# On each agent node (one at a time)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.3+k3s1" K3S_URL="https://<server-ip>:6443" K3S_TOKEN="<token>" sh -
```

Always upgrade the server node first, then agents one at a time.

### Useful kubectl commands

```bash
# Node resource usage — requires metrics-server, which k3s does NOT install by default.
# Install: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl top nodes

# Pod resource usage
kubectl top pods -n astralcloud

# Describe a failing pod
kubectl describe pod <pod-name> -n astralcloud

# Follow pod logs
kubectl logs -f <pod-name> -n astralcloud

# Exec into a running container
kubectl exec -it <pod-name> -n astralcloud -- sh

# Watch pod status
kubectl get pods -n astralcloud -w

# Check events (useful for crash loops)
kubectl get events -n astralcloud --sort-by='.lastTimestamp'

# Force delete a stuck pod
kubectl delete pod <pod-name> -n astralcloud --grace-period=0 --force
```

### Drain and cordon (maintenance)

```bash
# Prevent new pods scheduling on a node
kubectl cordon <node-name>

# Evict existing pods (for maintenance / upgrade)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Re-enable scheduling after maintenance
kubectl uncordon <node-name>
```

---

## Troubleshooting

| Symptom                   | Where to look                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------- |
| Pod stuck in `Pending`    | `kubectl describe pod` — check Events for resource or node affinity issues                              |
| Pod in `CrashLoopBackOff` | `kubectl logs <pod> --previous` — check for startup errors                                              |
| Image pull failure        | `kubectl describe pod` — check `ImagePullBackOff`; verify image exists and is ARM64                     |
| PVC stuck in `Pending`    | `kubectl describe pvc` — check if `storageClassName` matches available StorageClass                     |
| Service unreachable       | `kubectl get endpoints` — if empty, the pod selector doesn't match Service selector                     |
| Ingress 404/502           | Check ingress controller logs; verify `ingressClassName` and backend service/port                       |
| Node `NotReady`           | `kubectl describe node` — check conditions; SSH to node and check `systemctl status k3s` or `k3s-agent` |

---

## Security Rules

- Never run workloads as `root` (UID 0) — set `securityContext.runAsNonRoot: true`
- Set `allowPrivilegeEscalation: false` on all containers unless explicitly required
- Use `NetworkPolicy` to restrict pod-to-pod traffic in production — note: k3s's default CNI (Flannel) does **not** enforce NetworkPolicy; install Calico or Cilium as the CNI if you need NetworkPolicy enforcement
- Store all secrets in k8s `Secret` objects, not `ConfigMap`
- Rotate the k3s node token periodically in production clusters
- Use Keycloak OIDC for all user-facing services — never expose unauthenticated endpoints to the LAN

---

## Important Notes

- Keep k3s version consistent across all nodes — mixed versions cause subtle API compatibility issues
- `local-path-provisioner` binds PVs to a specific node — if a pod reschedules to a different node, it cannot access its data; account for this in your workload design
- Helm `upgrade --install` is idempotent and safe to run in CI; plain `helm install` fails if the release already exists
- Always run `helm lint` and `helm template ... --debug > /dev/null` in CI before merging Helm chart changes
- After `helm dependency update`, commit the updated `Chart.lock` and `charts/` directory
