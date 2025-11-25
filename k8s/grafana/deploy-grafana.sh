#!/bin/bash

set -e

NAMESPACE="monitoring"
SERVICE="grafana"
LOCAL_PORT=3000
REMOTE_PORT=3000

#echo "Applying namespace..."
#kubectl apply -f namespace.yaml

#echo "Applying InfluxDB secret..."
#kubectl apply -f secret-influx-auth.yaml

echo "Applying Grafana secret..."
kubectl apply -f grafana-secrets.yaml

echo "Applying Grafana-Datasource (InfluxDB v1) ..."
kubectl apply -f grafana-datasource.yaml

echo "Applying Grafana-Dashboards provisioning ..."
kubectl apply -f grafana-dashboard-providers.yaml

echo "Dashboard JSON (k6 + Kubernetes CPU) ..."
kubectl apply -f grafana-dashboard-k6.yaml

echo "Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml

echo "Creating Grafana service..."
kubectl apply -f grafana-service.yaml

echo "==================================="

echo "Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n "$NAMESPACE" --timeout=120s

echo "Starting port-forward in background..."
#kubectl port-forward svc/grafana 3000:3000 -n monitoring
kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} -n "${NAMESPACE}" >/dev/null 2>&1 &

PF_PID=$!

echo "Port-forward started with PID: ${PF_PID}"
echo "Grafana is available at: http://localhost:${LOCAL_PORT}"
echo "To stop port-forward run: kill ${PF_PID}"