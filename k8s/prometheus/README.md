## Prometheus + kube-state-metrics

### Deploy kube-state-metrics:
It's for exporting HPA, pod, and deployment metrics
- ServiceAccount
- ClusterRole
- ClusterRoleBinding 
- Deployment
- Service

```shell
kubectl apply -f kube-state-metrics.yaml
```
debug it:

```shell
kubectl get pods -n monitoring -l app=kube-state-metrics
kubectl port-forward -n monitoring svc/kube-state-metrics 8080:8080
# then curl http://localhost:8080/metrics

```

### Deploy Prometheus:
RBAC + ConfigMap + Deployment + Service

- Prometheus ServiceAccount 
- ClusterRole
- ClusterRoleBinding
- Prometheus configMap
- Deployment
- Service
```shell
kubectl apply -f prometheus.yaml
```

debug Prometheus UI:

```shell
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# then open http://localhost:9090/targets and verify targets are up
```
Check **Grafana datasource:**
Open Grafana UI → Configuration → Data sources → Prometheus
