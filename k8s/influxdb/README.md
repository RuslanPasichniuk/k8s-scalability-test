## Use [deploy-influxdb.sh](deploy-influxdb.sh) for deploy 


### What will heppend after deploy:
- InfluxDB will create authorization (INFLUXDB_HTTP_AUTH_ENABLED=true). 
- Via ConfigMap will be created:
  - DB k6 
  - Retention policy for 30 deys

#### Grafana, k6 Job або будь-який інший компонент можуть отримати креденшали через Secret.

### DEBUG:
 перевірка що K6 записав результати в DB
 
```shell
kubectl get pods -n monitoring | grep influxdb
kubectl exec -it -n monitoring <influxdb-pod> -- /bin/bash
#run CLI InfluxDB 1.8
influx -username admin -password admin123 -database k6
#=> Connected to http://localhost:8086 version 1.8.10
SHOW MEASUREMENTS;
#=> ttp_reqs, latency, vus ...
SELECT * FROM http_reqs LIMIT 5;
```
через curl з іншого пода
```shell
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- sh
curl -G "http://admin:admin123@influxdb.observability.svc.cluster.local:8086/query" --data-urlencode "db=k6" --data-urlencode "q=SHOW MEASUREMENTS"
```

```shell
kubectl exec -n monitoring deploy/influxdb -- influx -precision rfc3339 -username admin -password admin123 -execute 'SHOW MEASUREMENTS' -database k6
```