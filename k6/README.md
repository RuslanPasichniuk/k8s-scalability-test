# Running the Load Test


Execute the following command inside the cluster or from a runner with access:
```
k6 run load-test.js
```

### What to observe
- Apache CPU usage rises
- HPA begins scaling pods
- Replica count increases in `kubectl get deploy -w`
- Grafana dashboards show elasticity and balancing