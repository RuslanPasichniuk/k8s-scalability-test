#!/bin/bash
set -e

NAMESPACE="default"

#echo "1. Creating namespace..."
#kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "2. Deploying Apache Deployment..."
kubectl apply -f apache-deployment.yaml

echo "3. Deploying Apache Service (ClusterIP)..."
kubectl apply -f apache-service.yaml

echo "2. Deploying HPA ..."
kubectl apply -f apache-hpa.yaml

echo "4. Waiting for External IP if LoadBalancer ..."
while true; do
    EXTERNAL_IP=$(kubectl get svc apache-svc -n $NAMESPACE --output=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -n "$EXTERNAL_IP" ]]; then
        break
    fi
    echo "Waiting for LoadBalancer IP..."
    sleep 5
done

echo "External IP received: $EXTERNAL_IP"

TARGET_URL="http://$EXTERNAL_IP/"

echo "5. Creating k6 script configmap..."
kubectl create configmap k6-script --from-file=./k6/load-test.js -n monitoring

echo "6. Delete k6 Job if exists..."
kubectl delete -f k6-job.yaml

echo "7. Applying k6 job..."
kubectl apply -f k6-job.yaml

echo "8. Waiting for job to start..."
sleep 5

POD=$(kubectl get pods -n $NAMESPACE -l job-name=k6-load-test -o jsonpath='{.items[0].metadata.name}')

echo "9. Streaming k6 logs..."
kubectl logs -f $POD -n $NAMESPACE
