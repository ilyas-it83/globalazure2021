# Agenda

## MicroService? 

"Services are small in size, messaging-enabled, bounded by contexts, autonomously developed, independently deployable,decentralized and built and released with automated processes" - WIKI

## Intro to Service Mesh

"**A dedicated infrastructure layer for facilitating service-to-service communications between services or microservices, using a proxy**"

![Intro to Service Mesh](https://res.cloudinary.com/stackrox/v1564617364/servicemesh2_my8hwn.png "Intro to Service Mesh")

## How does it work

![Intro to Service Mesh](https://www.redhat.com/cms/managed-files/service-mesh-1680.png "Intro to Service Mesh")


## Intro to Istio

- Open source service mesh that helps to run distributed, microservices-based apps anywhere.

- Why use Istio? Istio enables developers to 
  - secure
  - connect
  - monitor microservices

![Intro to Service Mesh](https://istio.io/latest/docs/ops/deployment/architecture/arch.svg "Intro to Service Mesh")


## Features of Istio

###### Traffic Management
- Request routing
- Fault injection
- Traffic shifting
- Querying metrics
- Visualizing metrics
- Accessing external services
- Visualizing your mesh
![Traffic Management](https://istio.io/v1.1/docs/concepts/traffic-management/TrafficManagementOverview.svg)

###### Security
- Identity and certificate management
- Authentication
- Authorization  
![Security Management](https://istio.io/v1.3/docs/concepts/security/overview.svg)

###### Observability
- Metrics (latency, traffic, errors, and saturation)
- Distributed Traces.
- Access Logs
  
![Observability -fullwidth](https://istio.io/v1.6/docs/tasks/observability/kiali/kiali-graph.png)

## Pre-Requisites

```
1. Kubernetes Cluster (eg. minikube, DockerforDesktop with K8s or Azure Kubernetes Service)
2. Docker
3. Helm (Optional)
4. Istio
```

**Check if all of them are in place**
``` bash {cmd}
kubectl version && docker version && helm version && istioctl version
```

## Istio Setup

```bash {cmd}
Linux:

curl -L https://istio.io/downloadIstio | sh - (preferred for linux)

Windows:
https://github.com/istio/istio/releases/tag/1.9.2 (Download and unzip and add the exe to the PATH)

(or)

choco install istioctl
```

## Getting Started - Demo

### About the sample app

![Intro to Service Mesh](https://istio.io/latest/docs/examples/bookinfo/noistio.svg "Intro to Service Mesh")

Reference: https://istio.io/latest/docs/examples/bookinfo/


<p style="color:red">Step 1: Install the demo profile </p>

```bash {cmd}
istioctl install --set profile=demo -y 

istioctl verify-install

```
<p style="color:red">Step 2: Create a namespace </p>

```bash {cmd}
# Create namespace
kubectl create ns globalazure

# Set the namespace
kubectl config set-context --current --namespace=globalazure

# Validate it
kubectl config view --minify | grep namespace:
```

<p style="color:red">Step 3: Add label to the target namespace to enable automatic side-car injection </p>

```bash {cmd}
kubectl label namespace globalazure istio-injection=enabled

kubectl get ns globalazure --show-labels

```

<p style="color:red">Step 4:  Deploy the sample application</p>

```bash {cmd}
kubectl apply -f 1_bookinfo.yaml -n globalazure

# Check if all the pods,services are up and running
kubectl get all -n globalazure 

# check the rating pod for its readiness

kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

http://localhost/productpage

```
<p style="color:red">Step 5: Expose the application to the external world</p>

```bash {cmd}
# Create Ingress Gateway and Virtual Service

kubectl apply -f 2_bookinfo-gateway.yaml -n globalazure 

# Check if there is any issue with the ingress
istioctl analyze -n globalazure  

# Getting Ingress IP & Port
kubectl get svc istio-ingressgateway -n istio-system

```

<p style="color:red">Step 6: Check the application</p>

http://localhost/productpage

## Traffic Management - Demo

##### Request routing

###### Apply destination rules & Virtual services
```bash {cmd}
kubectl apply -f traffic/destination-rule-all.yaml
kubectl apply -f traffic/virtual-service-all-v1.yaml

http://localhost/productpage

```
###### HTTP Header based routing
```bash {cmd}
kubectl apply -f traffic/virtual-service-reviews-test-v2.yaml

http://localhost/productpage

```

##### Traffic shifting
```bash {cmd}
kubectl apply -f traffic/virtual-service-all-v1.yaml

kubectl apply -f traffic/virtual-service-reviews-50-v3.yaml
kubectl apply -f traffic/virtual-service-reviews-80-20.yaml
kubectl apply -f traffic/virtual-service-reviews-90-10.yaml

## 100% routing
kubectl apply -f traffic/virtual-service-reviews-v3.yaml

```
##### Fault injection

```bash {cmd}
kubectl apply -f traffic/virtual-service-reviews-v3.yaml
kubectl apply -f traffic/virtual-service-ratings-test-abort.yaml

```

## Observability - Demo


### Deply Addons

```bash {cmd}
kubectl apply -f observability/

#Generate some load

./loadgen.sh
```


### Jaeger for Distributed tracing
```bash {cmd}
istioctl dashboard jaeger
```

### Envoy web ui

```bash {cmd}
istioctl dashboard envoy deployment/productpage-v1

```

### Kiali for Monitoring Traffic Flow and Health of services

```bash {cmd}
istioctl dashboard kiali
```

### Prometheus for monitoring and alerting

```bash {cmd}
istioctl dashboard prometheus

e.g. istio_requests_total

```

### Grafana for distributed tracing

```bash {cmd}
istioctl dashboard grafana

http://localhost:3000/dashboard/db/istio-service-dashboard
```

### Zipkin for distributed tracing

```bash {cmd}
istioctl dashboard zipkin

```
## Security - Demo


### Athentication

```bash {cmd}
kubectl create ns foo
kubectl create ns bar
kubectl create ns legacy

kubectl label namespace foo istio-injection=enabled
kubectl label namespace bar istio-injection=enabled

kubectl apply -f security/mtls/httpbin.yaml -n foo
kubectl apply -f security/mtls/sleep.yaml -n foo

kubectl apply -f security/mtls/httpbin.yaml -n bar
kubectl apply -f security/mtls/sleep.yaml -n bar

kubectl apply -f security/mtls/sleep.yaml -n legacy

for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s  -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done

kubectl apply -f security/mtls/mesh-mtls.yaml -n foo

kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl -s http://httpbin.foo:8000/headers -s

kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s


```
### JWT

```bash {cmd}

kubectl apply -f security/jwt/httpbin-gateway.yaml -n foo

http://localhost:80

kubectl apply -f security/jwt/auth-policy.yaml -n istio-system

curl "http://localhost:80/headers" -s -o /dev/null -w "%{http_code}\n"

curl --header "Authorization: Bearer deadbeef" "http://localhost:80/headers" -s -o /dev/null -w "%{http_code}\n"

curl --header "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg" "http://localhost:80/headers" -s -o /dev/null -w "%{http_code}\n"


```


## Next step - Getting started
- https://istio.io/latest/docs/setup/getting-started/

### Sources 
- https://en.wikipedia.org/wiki/Service_mesh
- https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh
- https://www.stackrox.com/post/2019/06/getting-started-with-istio-service-mesh-what-is-it-and-what-does-it-do/



