import http from 'k6/http';
import { sleep } from 'k6';
import { check } from 'k6';
import { Trend } from 'k6/metrics';

export let options = {
    stages: [
        { duration: '60s', target: 200 }, // Ramp up to 150 VUs
        { duration: '60s', target: 200 }, // Hold at 150 VUs
        { duration: '30s', target: 0 },   // Hold at 150 VUs
    ]
};

const latency = new Trend('latency');

export default function () {
    let res = http.get('http://apache-svc.default.svc.cluster.local/');
    //let res = http.get('http://google.com/');
    check(res, {
        'status is 200': (r) => r.status === 200,
    });
    latency.add(res.timings.duration);
    sleep(0.5);
}


