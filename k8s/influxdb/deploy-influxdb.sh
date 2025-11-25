#!/bin/bash
set -e

NAMESPACE="monitoring"
PVC_NAME="influxdb-pvc"

echo ""
echo "=== 1. Create namespace (якщо потрібно) ==="
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || \
kubectl create namespace $NAMESPACE

echo "=== 2. Create PersistentVolumeClaim ==="
kubectl apply -f influx-pvc.yaml -n $NAMESPACE

echo "=== 3. Create Secret for InfluxDB ==="
kubectl apply -f influx-secret.yaml -n $NAMESPACE

echo "=== 4. Create InfluxDB init file ==="
kubectl apply -f influx-init.yaml -n $NAMESPACE

echo "=== 5. Create Deployment InfluxDB ==="
kubectl apply -f influxdb-deployment.yaml -n $NAMESPACE

echo "=== 6. Create Service InfluxDB ==="
kubectl apply -f influxdb-service.yaml -n $NAMESPACE

echo "=== 7. Waiting while InfluxDB will be ready ==="
kubectl rollout status deployment/influxdb -n $NAMESPACE

echo "✅ InfluxDB ready and located in namespace: $NAMESPACE"
kubectl get pods -n $NAMESPACE -l app=influxdb
sleep 2
kubectl get svc -n $NAMESPACE

echo "
=== 👀[DEBUG] ==="
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=influxdb | grep influxdb | awk '{print $1}')

echo "[!] kubectl logs $POD_NAME -n $NAMESPACE"
echo "[*] kubectl exec -it -n $NAMESPACE $POD_NAME -- /bin/bash"
echo "[$] influx -username admin -password admin123 -database k6"
echo "[$] SHOW MEASUREMENTS"
echo "[$] SELECT * FROM http_reqs LIMIT 5"

echo "
=== Delete name space ==="
echo "[$] kubectl delete ns monitoring"
echo ""
