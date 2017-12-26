OpenLab CI jobs definitions
===========================

This repo contains a set of Ansible playbooks which are used by the OpenLab CI
system. Any 3rd project want to integrate with the OpenLab CI, need to add
jobs definitions into this repo firstly.

Jobs naming notations
---------------------
To unify the jobs name format, we have the following naming notations:

    {project}-{test type}-{backend}-{service}

- The *project* usually is the name of the git repo which contains tests to run.
- The *test type* is the type of tests to run, e.g. acceptance tests, unit test.
- The *backend* is the test environment provider, default is `Devstack`, optionally.
- The *service* is the specific OpenStack service which this job will run against,
  optionally.

For an example, the job definition about running the specific Trove related
acceptance tests of terraform-provider-openstack repo can be named as:

    terraform-provider-openstack-acceptance-test-trove

More information
----------------
Web page about OpenLab:

    http://openlabtesting.org/

Documentation about how to integrate OpenLab CI:

    https://raw.githubusercontent.com/theopenlab/cicd-howto
