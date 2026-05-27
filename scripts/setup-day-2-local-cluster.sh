#!/usr/bin/env bash
# InsightHub - Setup Day 2 local Kubernetes cluster for MCP testing.
#
# Usage:
#   bash scripts/setup-day-2-local-cluster.sh
#
# Optional env:
#   CLUSTER_NAME=insighthub-lab
#   NAMESPACE=insighthub
#   KUBECONFIG_OUT="$HOME/.kube/mcp-viewer.kubeconfig"
#   CLUSTER_TOOL=kind|k3d

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-insighthub-lab}"
NAMESPACE="${NAMESPACE:-insighthub}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-mcp-readonly}"
ROLE_NAME="${ROLE_NAME:-mcp-readonly}"
KUBECONFIG_OUT="${KUBECONFIG_OUT:-$HOME/.kube/mcp-viewer.kubeconfig}"
CLUSTER_TOOL="${CLUSTER_TOOL:-kind}"

info() { printf "\033[36m[INFO]\033[0m %s\n" "$1"; }
ok() { printf "\033[32m[OK]\033[0m %s\n" "$1"; }
fail() { printf "\033[31m[FAIL]\033[0m %s\n" "$1"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

create_cluster() {
  case "$CLUSTER_TOOL" in
    kind)
      need_cmd kind
      if kind get clusters | grep -qx "$CLUSTER_NAME"; then
        ok "kind cluster '$CLUSTER_NAME' already exists"
      else
        info "Creating kind cluster '$CLUSTER_NAME'"
        kind create cluster --name "$CLUSTER_NAME"
      fi
      kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
      ;;
    k3d)
      need_cmd k3d
      if k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
        ok "k3d cluster '$CLUSTER_NAME' already exists"
      else
        info "Creating k3d cluster '$CLUSTER_NAME'"
        k3d cluster create "$CLUSTER_NAME"
      fi
      kubectl config use-context "k3d-$CLUSTER_NAME" >/dev/null
      ;;
    *)
      fail "Unsupported CLUSTER_TOOL='$CLUSTER_TOOL'. Use kind or k3d."
      ;;
  esac
}

apply_rbac() {
  info "Creating namespace and read-only RBAC"
  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  kubectl create serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $ROLE_NAME
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log", "services", "endpoints", "events", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch"]
EOF

  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $ROLE_NAME
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $ROLE_NAME
subjects:
  - kind: ServiceAccount
    name: $SERVICE_ACCOUNT
    namespace: $NAMESPACE
EOF
}

write_readonly_kubeconfig() {
  info "Writing read-only kubeconfig to $KUBECONFIG_OUT"
  mkdir -p "$(dirname "$KUBECONFIG_OUT")"

  local current_context cluster_name server ca_data token
  current_context="$(kubectl config current-context)"
  cluster_name="$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$current_context\")].context.cluster}")"
  server="$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$cluster_name\")].cluster.server}")"
  ca_data="$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$cluster_name\")].cluster.certificate-authority-data}")"
  token="$(kubectl create token "$SERVICE_ACCOUNT" -n "$NAMESPACE")"

  cat > "$KUBECONFIG_OUT" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: $CLUSTER_NAME
    cluster:
      certificate-authority-data: $ca_data
      server: $server
contexts:
  - name: $CLUSTER_NAME-$SERVICE_ACCOUNT
    context:
      cluster: $CLUSTER_NAME
      namespace: $NAMESPACE
      user: $SERVICE_ACCOUNT
current-context: $CLUSTER_NAME-$SERVICE_ACCOUNT
users:
  - name: $SERVICE_ACCOUNT
    user:
      token: $token
EOF

  chmod 600 "$KUBECONFIG_OUT"
}

deploy_sample_workload() {
  info "Deploying sample nginx workload in namespace '$NAMESPACE'"
  kubectl create deployment nginx --image=nginx:1.27-alpine -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  kubectl expose deployment nginx --port=80 -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  kubectl rollout status deployment/nginx -n "$NAMESPACE" --timeout=90s
}

verify() {
  info "Verifying read-only access"
  kubectl --kubeconfig "$KUBECONFIG_OUT" get pods -n "$NAMESPACE" >/dev/null

  local can_get can_delete
  can_get="$(kubectl auth can-i get pods --as="system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT" -n "$NAMESPACE")"
  can_delete="$(kubectl auth can-i delete pods --as="system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT" -n "$NAMESPACE")"

  [ "$can_get" = "yes" ] || fail "Expected get pods permission to be yes, got: $can_get"
  [ "$can_delete" = "no" ] || fail "Expected delete pods permission to be no, got: $can_delete"

  ok "Read-only kubeconfig can list pods and cannot delete pods"
}

need_cmd kubectl
create_cluster
apply_rbac
write_readonly_kubeconfig
deploy_sample_workload
verify

cat <<EOF

Day 2 local cluster is ready.

Cluster tool:       $CLUSTER_TOOL
Cluster name:       $CLUSTER_NAME
Namespace:          $NAMESPACE
Read-only kubeconf: $KUBECONFIG_OUT

Use this env for Kubernetes MCP:
  KUBECONFIG=$KUBECONFIG_OUT

Example check:
  kubectl --kubeconfig "$KUBECONFIG_OUT" get pods -n "$NAMESPACE"
EOF
