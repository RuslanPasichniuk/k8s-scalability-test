#!/bin/bash

NAMESPACE="monitoring"
SERVICE="prometheus"
LOCAL_PORT=9090
REMOTE_PORT=9090

echo "********* DEPLOY $SERVICE in ns $NAMESPACE ***********"
set -e

echo "1. Applying Kube-State-Metrics..."
kubectl apply -f kube-state-metrics.yaml --force

echo "2. Applying Prometheus ..."
kubectl apply -f prometheus.yaml --force

echo "3. Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n "$NAMESPACE" --timeout=120s

echo "✅ Prometheus ready in namespace $NAMESPACE"
echo ""
echo "8. Starting port-forward in background...
      [$] kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} -n "${NAMESPACE}""
kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} -n "${NAMESPACE}" >/dev/null 2>&1 &
echo ""
echo "======================================="
kubectl get pods -n $NAMESPACE -l app=prometheus
sleep 2
kubectl get svc -n $NAMESPACE

PF_PID=$!
echo ""
echo "=== 👀 [ DEBUG ] ==="
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=prometheus | grep prometheus | awk '{print $1}')
echo "** Port-forward started with PID: ${PF_PID} **"
echo "  Grafana is available at: http://localhost:${LOCAL_PORT}"
echo "  To stop port-forward run: kill ${PF_PID}"
echo "  List of processes on port-${REMOTE_PORT}: lsof -i :${REMOTE_PORT}"
echo ""
echo "[*] kubectl exec -it -n $NAMESPACE $POD_NAME -- /bin/bash"
echo "[!] kubectl logs $POD_NAME -n $NAMESPACE | egrep \"level=warn|level=error\" --color=always"
echo ""
echo "***************END*********************"
