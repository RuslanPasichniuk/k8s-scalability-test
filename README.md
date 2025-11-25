# Kubernetes Scalability Demo
This repository demonstrates how Kubernetes scales pods under load using 
 - Apache HTTP server,
 - Horizontal Pod Autoscaler (HPA),
 - K6 load generator. 
 - Observability: Grafana + Prometheus for visualization
   - Grafana gets: 
   - [TODO] Kubernetes metrics from Prometheus 
   - K6 metrics from InfluxDB
   
 В результаті у Grafana ти бачиш:
  - K6 RPS (requests per second)
  - Latency (p90 / p95 / p99)
  - CPU / Memory pods 
  - Pod count (autoscaling in real time)
  - Startup time 
  - Load balancing behaviour

## Steps
1. Deploy InfluxDB [deploy-influxdb.sh](k8s/influxdb/deploy-influxdb.sh)
2. Deploy Grafana [deploy-grafana.sh](k8s/grafana/deploy-grafana.sh)
3. Deploy Apache + Service + HPA 
4. Start K6 load test
   5. you can use [deploy-apache-run-test.sh](k8s/deploy-apache-run-test.sh)
3. Observe scaling behavior in Kubernetes
4. Visualize CPU and replica count in Grafana


## project structure:
```
k8s-scalability-test/
├── k8s/
| |-- grafana/
| |-- influxdb/
│ ├── apache-deployment.yaml
│ ├── apache-service.yaml
│ ├── apache-hpa.yaml
| |-- deploy-apache-run-test.sh
│ └── README.md
├── k6/
│ ├── load-test.js
│ └── k6-job.yaml
└── README.md
```

## Step by step for the newcomers:
Preconditions: Installed: gcloud, kubectl, and helm. (optionally k6 locally)

###  Adjust GCP CLI and project:
```shell
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud config set compute/zone europe-west1-b   # або інша зона
```

### create GKE cluster:
```shell
gcloud container clusters create showcase-cluster \
  --zone=europe-west1-b \
  --num-nodes=3 \
  --machine-type=e2-medium
```
verify:
```shell
gcloud container clusters get-credentials showcase-cluster --zone=europe-west1-b
kubectl get nodes
```
### Create namespace 
```shell 
# name-space.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
```
```shell
kubectl apply -f name-space.yaml
```
### Deploy InfluxDB or exec [deploy-influxdb.sh](k8s/influxdb/deploy-influxdb.sh)
```shell
echo "1. Create namespace (if needed)"
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || \
kubectl create namespace $NAMESPACE

echo "2. Create PersistentVolumeClaim"
kubectl apply -f influxdb/influx-pvc.yaml

echo "3. Create Secret for InfluxDB"
kubectl apply -f influxdb/influx-secret.yaml

echo "4. Create InfluxDB init file"
kubectl apply -f influxdb/influx-init.yaml

echo "5. Create Deployment InfluxDB"
kubectl apply -f influxdb/influxdb-deployment.yaml

echo "6. Create Service InfluxDB"
kubectl apply -f influxdb/influxdb-service.yaml
```

### Deploy Grafana or use [deploy-grafana.sh](k8s/grafana/deploy-grafana.sh)
```shell
echo "1. Applying Grafana secret..."
kubectl apply -f grafana-secrets.yaml --force

echo "2. Applying Grafana-Datasource (InfluxDB v1) ..."
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
```

### Install metrics-server ( kubectl top and HPA needs to see metrics CPU)
```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# verify:
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods
```
If **kubectl top** doesn't work — wait for a minute and check the logs 
```bash
kubectl -n kube-system logs deployment/metrics-server
```

### [TODO] install Prometheus + Grafana, via packet manager HELM 

[INFO]: The easiest way to avoid installing Prometheus/Grafana is to use **_kubectl top_** and **_kubectl get hpa -w_**; 
However, Grafana is recommended for PM.

**community chart**
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

**connect to Grafana temporary via port-forward:**
- in browser goto http://localhost:3000
- default creds: **_admin_** / **_prom-operator_** (or see secrets)

```shell
# знайди Grafana service name (може бути prometheus-grafana)
kubectl get svc -n monitoring
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```
get secrets:
```shell
kubectl get secret prometheus-grafana -n monitoring -o yaml
#decode base64
kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 --decode
kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-user}' | base64 --decode

```

### You can execute all the steps listed below by running the script. [deploy-apache-run-test.sh](k8s/deploy-apache-run-test.sh)
### Deploy test service Apache 
**Apache Deployment + Service + HPA**
```shell
kubectl apply -f k8s/apache-deployment.yaml
kubectl apply -f k8s/apache-service.yaml
kubectl apply -f k8s/apache-hpa.yaml
#verify
kubectl get deploy apache-demo
kubectl get pods -l app=apache-demo
kubectl get svc apache-svc
kubectl get hpa apache-hpa
```
WARN: HPA works **ONLY** if the container has resources.requests.cpu — validate that **_deployment_** has _requests_ (in apache-deployment they are).

### Make Apache accessible for Load Tests
**3 options:**
#### 1. For fast demo — change Service to LoadBalancer
Take some money for _**EXTERNAL-IP**_, check if the cluster allows to use of LB 
```shell
kubectl patch svc apache-svc -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc apache-svc -w
# when EXTERNAL-IP appears — use it in k6

```

#### 2. Port-Forward instead of LB
In this case, you have to update tests: http://localhost:8080
```shell
kubectl port-forward svc/apache-svc 8080:80
# Then in k6 use http://host.docker.internal:8080 or http://localhost:8080 (звідки запускаєш k6)
```
#### 3. Run k6 into a cluster (recommended, no need LB)
- Create ConfigMap with script k6:
```shell
kubectl create configmap k6-script --from-file=./k6/load-test.js -n monitoring
```
- Run Pod/Job, that mounts this ConfigMap and executes **_k6 run_**:
```shell
kubectl apply -f k6/k6-job.yaml
cleanup:
kubectl delete job k6-load-test
```
- Or run it manually:
```shell
k6 run k6/load-test.js            # if k6 installed localy
# or
docker run --rm -v $(pwd)/k6:/scripts loadimpact/k6 run /scripts/load-test.js
```


### [INFO] що показати під час демо
- Чи збільшується CPU в pod (черга CPU). 
- Через який час HPA створює додатковий pod (scale up latency). 
- Чи балансується трафік між pod (перевірити kubectl get pods -o wide і логи Apache). 
- Як довго триває scale down (за замовчуванням scale-down має затримку; можна показати це). 
- Показати kubectl describe hpa → Events та Metrics (помітно як HPA реагує на метрики).