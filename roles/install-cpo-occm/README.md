The ansible role deploys openstack-cloud-controller-manager in a k8s cluster.

Prerequisites:

* The playbook is running on a host with devstack installed.
* k8s cluster is running inside a VM on the devstack host.
* kubectl is installed.
* KUBECONFIG is set in the environment.