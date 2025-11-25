
## Deploy Grafana
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


5️⃣ Пояснення


Datasource provisioning → автоматично додає InfluxDB до Grafana при старті.


Dashboards → ConfigMap монтується в /var/lib/grafana/dashboards → автопідхоплення.


Secret → передає user/password без hardcode в YAML.


LoadBalancer → можна відкрити Grafana з браузера.



6️⃣ Перевірка


Після застосування YAML:


kubectl apply -f grafana-datasource.yaml
kubectl apply -f grafana-dashboard-k6.yaml
kubectl apply -f grafana-deployment.yaml



Подивитися статус:


kubectl get pods -n observability
kubectl get svc -n observability grafana



Відкрити Grafana у браузері → метрики з k6 + pod CPU повинні з’явитись.



Якщо хочеш, я можу згенерувати повний deploy.sh, який за один раз піднімає:


InfluxDB


k6 Job


Grafana з Datasource + Dashboards


І відразу можна запускати тест.
Хочеш, щоб я так зробив?