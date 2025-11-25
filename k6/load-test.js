import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
    stages: [
        { duration: '20s', target: 50 },
        { duration: '20s', target: 150 },
        { duration: '20s', target: 300 }
    ]
};

export default function() {
    http.get('http://apache-svc.default.svc.cluster.local');
    sleep(0.1);
}
