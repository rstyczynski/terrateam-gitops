## day-2_ops2

Ansible Engine is provided with capability to protect pipeline from installing collections from public sources allowing only dir and git ones. Playbook uses git based collection to interact with DuckGoGo search, having in a requirements.yml public collection. You will see how the pipeline protects from such configurations. Some plays can't be used in check mode due to some reasons. Pipeline provides possibility skip the check mode.

This example uses GitHub pull request interaction assuming you are familiar with this interface. Look at day2-ops1 description for details.

### Goals

* install collection
* familiarize with galaxy firewall
* pipeline control to skip check mode

### CLI


In the first step execute the playbook at the command line in a check mode.

```bash
cd day-2_ops2
ansible-playbook duck.yml --check
```

to receive the following output:

```text
```

### Pipeline

### Summary

