
## Use [deploy-grafana.sh](deploy-grafana.sh) for installing Grafana 
or do it manually... 

### Deploy Grafana
```shell
# you can find how install it with prometheus in .README.md
helm install grafana grafana/grafana -n monitoring --set service.type=LoadBalancer
```

### Add InfluxDB as data source to Grafana 
```shell
kubectl get svc influxdb -n monitoring
# build URL by pattern: <service-name>.<namespace>.svc.cluster.local
```

### in Grafana add DataSource: InfluxDB
- Перейти Configuration → Data Sources → Add data source 
- Вибрати InfluxDB 
- Заповнити поля:
  - URL: http://influxdb.loadtest.svc.cluster.local:8086; 
    - http://<service-name>.<namespace>.svc.cluster.local:PORT
  - Database: (назва бази, наприклад k6)
  - User / Password: якщо створено 
  - HTTP Method: GET або POST 
- Натиснути Save & Test → має бути “Data source is working” 


### Add Grafana dashboard for K6
- Використати готовий JSON (наприклад grafana/dashboards/k6-dashboard.json)
  - У Grafana: Dashboard → Manage → Import 
  - Вставити JSON → створити dashboard
- Перевірити графіки 
  - Requests per second (RPS)
  - HTTP durations (p95)
  - Pod CPU / Memory usage 
  - Deployment replica count (через Prometheus або kube-state-metrics)
