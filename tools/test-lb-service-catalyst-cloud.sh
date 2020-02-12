#!/usr/bin/env bash

# Prerequisites:
#   1. This script is supposed to be running on a host has access to both openstack and kubernetes.
#   2. Make sure the openstack credential file exist (no need to be admin user).
#   3. kubectl is ready to talk with the kubernetes cluster.
#   4. It's recommended to run the script on a host with as less proxy to the public as possible, otherwise the
#      x-forwarded-for test will fail.
TIMEOUT=${TIMEOUT:-300}
CLUSTERNAME=${CLUSTERNAME:-kubernetes}
FLOATING_IP=${FLOATING_IP:-""}
NAMESPACE="octavia-lb-test"

########################################################################
## Name: wait_for_service
## Desc: Waits for a k8s service until it gets a valid IP address
## Params:
##   - (required) A k8s service name
########################################################################
function wait_for_service {
  local service_name=$1

  end=$(($(date +%s) + ${TIMEOUT}))
  while true; do
    ipaddr=$(kubectl -n $NAMESPACE describe service ${service_name} | grep 'LoadBalancer Ingress' | awk -F":" '{print $2}' | tr -d ' ')
    if [ "x${ipaddr}" != "x" ]; then
      printf "\n>>>>>>> Service ${service_name} is created successfully, IP: ${ipaddr}\n"
      export ipaddr=${ipaddr}
      break
    fi
    sleep 3
    now=$(date +%s)
    [ $now -gt $end ] && printf "\n>>>>>>> FAIL: Failed to wait for the Service ${service_name} created in time\n" && exit -1
  done
}

########################################################################
## Name: wait_for_service_deleted
## Desc: Waits for a k8s service deleted.
## Params:
##   - (required) A k8s service name
########################################################################
function wait_for_service_deleted {
    local service_name=$1

    end=$(($(date +%s) + ${TIMEOUT}))
    while true; do
        svc=$(kubectl -n $NAMESPACE get service | grep ${service_name})
        if [[ "x${svc}" == "x" ]]; then
            printf "\n>>>>>>> Service ${service_name} deleted\n"
            break
        fi
        sleep 3
        now=$(date +%s)
        [ $now -gt $end ] && printf "\n>>>>>>> FAIL: Failed to wait for the Service ${service_name} deleted\n" && exit -1
    done
}

########################################################################
## Name: create_deployment
## Desc: Makes sure the echoserver service Deployment is running
## Params: None
########################################################################
function create_deployment {
    printf "\n>>>>>>> Create a Deployment\n"
    kubectl -n $NAMESPACE get deploy echoserver > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        kubectl -n $NAMESPACE run echoserver --image=gcr.io/google-containers/echoserver:1.10 --image-pull-policy=IfNotPresent --port=8080
    fi
}

########################################################################
## Name: test_basic
## Desc: Create a k8s service and send request to the service external
##       IP
## Params: None
########################################################################
function test_basic {
    local service="test-basic"

    printf "\n>>>>>>> Create Service ${service}\n"
    cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: ${service}
  namespace: $NAMESPACE
spec:
  type: LoadBalancer
  loadBalancerIP: ${FLOATING_IP}
  selector:
    run: echoserver
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
EOF

    printf "\n>>>>>>> Waiting for the Service ${service} creation finished\n"
    wait_for_service ${service}

    printf "\n>>>>>>> Sending request to the Service ${service}\n"
    podname=$(curl -s http://${ipaddr} | grep Hostname | awk -F':' '{print $2}' | cut -d ' ' -f2)
    if [[ "$podname" =~ "echoserver" ]]; then
        printf "\n>>>>>>> Expected: Get correct response from Service ${service}\n"
    else
        printf "\n>>>>>>> FAIL: Get incorrect response from Service ${service}\n"
        exit -1
    fi

    printf "\n>>>>>>> Delete Service ${service}\n"
    kubectl -n $NAMESPACE delete service ${service}
}

########################################################################
## Name: test_forwarded
## Desc: Create a k8s service that gets the original client IP
## Params: None
########################################################################
function test_forwarded {
    local service="test-x-forwarded-for"
    local public_ip=$(curl -s ifconfig.me)
    local local_ip=$(ip route get 8.8.8.8 | head -1 | awk '{print $7}')

    printf "\n>>>>>>> Create the Service ${service}\n"
    cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: ${service}
  namespace: $NAMESPACE
  annotations:
    loadbalancer.openstack.org/x-forwarded-for: "true"
spec:
  type: LoadBalancer
  loadBalancerIP: ${FLOATING_IP}
  selector:
    run: echoserver
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
EOF

    printf "\n>>>>>>> Waiting for the Service ${service} creation finished\n"
    wait_for_service ${service}

    printf "\n>>>>>>> Sending request to the Service ${service}\n"
    orig_ip=$(curl -s http://${ipaddr} | grep  x-forwarded-for | awk -F'=' '{print $2}')
    if [[ "${orig_ip}" != "${local_ip}" && "${orig_ip}" != "${public_ip}" ]]; then
        printf "\n>>>>>>> FAIL: Get incorrect response from Service ${service}\n"
        exit -1
    else
        printf "\n>>>>>>> Expected: Get correct response from Service ${service}\n"
    fi

    printf "\n>>>>>>> Delete Service ${service}\n"
    kubectl -n $NAMESPACE delete service ${service}
}

########################################################################
## Name: test_internal
## Desc: Create an internal k8s service that shouldn't have external IP.
## Params: None
########################################################################
function test_internal {
    local service="test-internal"

    printf "\n>>>>>>> Create the internal Service ${service}\n"
    cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: ${service}
  namespace: $NAMESPACE
  annotations:
    service.beta.kubernetes.io/openstack-internal-load-balancer: "true"
spec:
  type: LoadBalancer
  selector:
    run: echoserver
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
EOF

    printf "\n>>>>>>> Waiting for the Service ${service} creation finished\n"
    wait_for_service ${service}

    lbname="kube_service_${CLUSTERNAME}_${NAMESPACE}_${service}"
    vip_port_id=(openstack loadbalancer show $lbname -c vip_port_id -f value)
    count=$(openstack floating ip list --port ${vip_port_id} | wc -l)
    if [[ $count > 1 ]]; then
        printf "\n>>>>>>> FAIL: Floating IP allocated for the Service ${service}\n"
        exit -1
    else
        printf "\n>>>>>>> Expected: No floating IP allocated for the Service ${service}\n"
    fi

    printf "\n>>>>>>> Delete Service ${service}\n"
    kubectl -n ${NAMESPACE} delete service ${service}
}


create_deployment
test_basic
test_forwarded
test_internal

printf "\n>>>>>>> Delete k8s resources\n"
kubectl -n ${NAMESPACE} delete deploy echoserver