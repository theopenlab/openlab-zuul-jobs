OpenLab CI jobs definitions
===========================

This repo contains a set of Ansible playbooks which are used by the OpenLab CI
system. Any 3rd project want to integrate with the OpenLab CI, need to add
jobs definitions into this repo firstly.

If this is first time you come to OpenLab, please start with OpenLab
[Getting Started](https://docs.openlabtesting.org/publications/).

Jobs naming notations
---------------------
To unify the jobs name format, we have the following naming notations:

    {project}-{test type}-{backend}-{service}-{version}

- The *project* usually is the name of the git repo which contains tests to run.
- The *test type* is the type of tests to run, e.g. acceptance test, integration test, funcational test, unit test.
- The *backend* is the test environment provider, include: deploying tools, public cloud, private cloud,
  e.g. devstack, kubeadm, minikube, opentelekoncloud, optionally, default is `devstack`.
- The *service* is the specific *backend* service which this job will run against, optionally, default is `core services`.
- The *version* is the specific *backend* version which this job will run against, optionally, default is `master`.

For an example, the job definition about running the specific Trove related
acceptance tests of terraform-provider-openstack repo can be named as:

    terraform-provider-openstack-acceptance-test-trove

And running spark integration test against kubernetes 1.13.0 that is deployed by minikube:

    spark-integration-test-minikube-k8s-1.13.0

More information
----------------
Web page about OpenLab:

> http://openlabtesting.org/

Development Guide:

> https://docs.openlabtesting.org/publications/contributors/development-guide
