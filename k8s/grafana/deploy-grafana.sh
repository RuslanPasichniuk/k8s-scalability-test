#!/bin/bash

NAMESPACE="monitoring"
SERVICE="grafana"
LOCAL_PORT=3000
REMOTE_PORT=3000
LABELS_APP="grafana"

echo "********* DEPLOY GRAFANA in ns $NAMESPACE ***********"
set -e

#echo "[PRECONDITIONS] Applying namespace..."
#kubectl apply -f grafana-namespace.yaml || true

#kubectl get namespace $NAMESPACE >/dev/null 2>&1 || \
#kubectl create namespace $NAMESPACE

#echo "Applying InfluxDB secret..."
#kubectl apply -f secret-influx-auth.yaml

echo "1. Applying Grafana secret..."
kubectl apply -f grafana-secrets.yaml --force

echo "2. Applying Grafana-Datasource (InfluxDB v1 and Prometheus) ..."
kubectl apply -f grafana-datasource.yaml --force

echo "3. Applying Grafana-Dashboards provisioning ..."
kubectl apply -f grafana-dashboard-providers.yaml --force

echo "4. Dashboard JSON (k6 + Kubernetes CPU) ..."
kubectl apply -f grafana-dashboard-k6.yaml --force

echo "5. Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml --force

echo "6. Creating Grafana service..."
kubectl apply -f grafana-service.yaml --force

echo "7. Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n "$NAMESPACE" --timeout=120s

echo "✅ Grafana готова та доступна у namespace $NAMESPACE"
echo "8. Starting port-forward in background...
      [$] kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} -n "${NAMESPACE}""
kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} -n "${NAMESPACE}" >/dev/null 2>&1 &
echo ""
echo "======================================="
kubectl get pods -n $NAMESPACE -l app=${LABELS_APP}
sleep 2
kubectl get svc -n $NAMESPACE

PF_PID=$!
echo ""
echo "=== 👀 [ DEBUG ] ==="
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app="${LABELS_APP}" | grep "${LABELS_APP}" | awk '{print $1}')
echo "** Port-forward started with PID: ${PF_PID} **"
echo "  Grafana is available at: http://localhost:${LOCAL_PORT}"
echo "  To stop port-forward run: kill ${PF_PID}"
echo "  List of processes on port-3000: lsof -i :3000"
echo ""
echo "[*] kubectl exec -it -n $NAMESPACE $POD_NAME -- /bin/bash"
echo "[!] kubectl logs $POD_NAME -n $NAMESPACE | egrep \"level=warn|level=error\" --color=always"
echo ""
echo "=== Validation that dashboards are set up ===
  [$] kubectl exec -n monitoring -it deploy/grafana -- ls /var/lib/grafana/dashboards
  [>]    <name>.json   <name2>.json
  [$] kubectl exec -n monitoring -it deploy/grafana -- ls /etc/grafana/provisioning/datasources
  [>]   influxdb.yaml
  [$] kubectl exec -n monitoring -it deploy/grafana -- ls /etc/grafana/provisioning/dashboards
  [>]   dashboards.yaml
"
echo "***************END*********************"
