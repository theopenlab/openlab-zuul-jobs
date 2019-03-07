andrewrothstein.java-oracle
=========
[![Build Status](https://travis-ci.org/andrewrothstein/ansible-java-oracle.svg?branch=master)](https://travis-ci.org/andrewrothstein/ansible-java-oracle)

Installs Oracle Java JRE or JDK.

Requirements
------------

See [meta/main.yml](meta/main.yml)

Role Variables
--------------

See [defaults/main.yml](defaults/main.yml)

Dependencies
------------

See [meta/main.yml](meta/main.yml)

Example Playbook
----------------

```yml
- hosts: servers
  roles:
    - role: andrewrothstein.java-oracle
```

License
-------

MIT

Author Information
------------------

Andrew Rothstein <andrew.rothstein@gmail.com>
