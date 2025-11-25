
# Kubernetes Apache + HPA Setup

## Deploy Apache

```
kubectl apply -f apache-deployment.yaml
```

## Create Service
```
kubectl apply -f apache-service.yaml
```

## Apply HPA
```
kubectl apply -f apache-hpa.yaml
```

## Monitor HPA
```
kubectl get hpa -w
kubectl get pods -w
```


## not implemented yet ...
```
## Open Grafana and watch:
- CPU usage per pod
- Deployment replica count
- HPA metrics
```
