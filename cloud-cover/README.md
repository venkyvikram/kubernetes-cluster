# Cloud Cover - Problem Statement:
Create two Kubernetes clusters using EC2 on AWS or GCE on GCP or VMs in Azure
Cluster 1: 1 master, 3 worker nodes
Cluster 2: 3 master, 1 worker node
Create a simple application with a frontend that interacts with Redis in the backend. The application should have a simple index page that displays.
“Hello CloudCover, you have <x> visitors on this page”
Where <x> is a counter that is fetched from Redis, and it gets incremented on every visit on the index page.
Containerize the frontend and backend. 
Deploy the frontend in cluster 1 in namespace “frontend”
Deploy the backend (Redis) in cluster 2 in namespace “backend”
Make sure your frontend is able to talk to your backend(inter-cluster communication), and the counter is fetched from Redis and displayed on the index page
Expected Solution
Candidate should share all the solution files by the end of the exercise:
Script used for setting up the clusters
Link to source code for frontend
Dockerfile for frontend and backend
Kubernetes YAML for all the Kubernetes resources created
Public Endpoint to hit the frontend



##Solution:
## Public Endpoint - http://34.71.18.5:31200/guestbook.php

The setup contains of two kubernetes clusters. 
Cluster 1: 1 master, 3 worker nodes
Cluster 2: 3 master, 1 worker node 

Both these clusters has been setup on GCE VMs & VM's has been setup with the terraform and the kubernetes has been setup through kubeadm

Cluster 1: 
This has setup with 1 master and 3 worker nodes. Frontend namespace is configured and the PHP application is deployed with 3 replicas.
The service is enabled with the nodeport and the GCP L4 external loadbalancer has been created with the node port on the L4 to access the public endpoint.
http://34.71.18.5:31200/guestbook.php

Cluster Details:
NAME       STATUS   ROLES    AGE   VERSION
cc-k8s-0   Ready    master   11h   v1.19.2
cc-k8s-1   Ready    worker   10h   v1.19.2
cc-k8s-2   Ready    worker   10h   v1.19.2
cc-k8s-3   Ready    worker   10h   v1.19.2

10.128.0.96 - Master
10.128.0.94 - Worker 1
10.128.0.92 - Worker 2
10.128.0.95 - Worker 3
Pod Network - 192.168.0.0/16

Frontend Resource:
kubectl get all -n frontend
NAME                           READY   STATUS    RESTARTS   AGE
pod/frontend-db8f74978-7272j   1/1     Running   0          19m
pod/frontend-db8f74978-8bt2r   1/1     Running   0          19m
pod/frontend-db8f74978-trq9l   1/1     Running   0          19m

NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/frontend   NodePort   10.100.136.34   <none>        80:31200/TCP   10h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/frontend   3/3     3            3           19m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/frontend-db8f74978   3         3         3       19m

----------------------------------------------------------------------------------------------------------------------------
Cluster 2:
This cluster has been setup with 5 VMs, with 3 master, 1 worker node and 1 HA proxy loadbalancer. Kubeadm has been used to initialize the setup with the etcd being HA.

The service is enabled with the nodeport and the GCP L4 internal loadbalancer has been created with the node port between the VM's for inter cluster communication.
tcp://10.128.0.201:30125

NAME                   STATUS   ROLES    AGE     VERSION
cc-multimaster-k8s-1   Ready    master   6h10m   v1.19.2
cc-multimaster-k8s-2   Ready    master   6h1m    v1.19.2
cc-multimaster-k8s-3   Ready    master   5h56m   v1.19.2
cc-multimaster-k8s-4   Ready    worker   5h47m   v1.19.2

10.128.0.99 - HA proxy
10.128.0.97 - Master 1
10.128.0.120 - Master 2
10.128.0.98 - Master 3
10.128.0.121 - Worker

Backend Resource:
kubectl get all -n backend
NAME                               READY   STATUS    RESTARTS   AGE
pod/redis-leader-fb76b4755-9phqk   1/1     Running   0          5h22m

NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/redis-leader   NodePort   10.106.92.161   <none>        6379:30125/TCP   89m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/redis-leader   1/1     1            1           5h22m

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/redis-leader-fb76b4755   1         1         1       5h22m

----------------------------------------------------------------------------------------------------------------------------

Log Validation:
Frontend:
192.168.3.1 - - [01/Oct/2020:21:11:35 +0000] "GET /guestbook.php HTTP/1.1" 200 390 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36"

Backend logs:
1:M 01 Oct 2020 21:06:49.044 * 1 changes in 3600 seconds. Saving...
1:M 01 Oct 2020 21:06:49.045 * Background saving started by pid 30
30:C 01 Oct 2020 21:06:49.048 * DB saved on disk
30:C 01 Oct 2020 21:06:49.048 * RDB: 0 MB of memory used by copy-on-write

Redis Cache Hit:
+1601586819.953769 [0 10.128.0.121:30172] "GET" "PHPREDIS_SESSION:af596c6b333490e72517313e418aae7c"
+1601586819.954275 [0 10.128.0.121:30172] "SETEX" "PHPREDIS_SESSION:af596c6b333490e72517313e418aae7c" "1440" "visit|i:9;"