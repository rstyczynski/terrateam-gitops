## day-2_ops2

Ansible Engine is provided with capability to protect pipeline from installing collections from public sources allowing only dir and git ones. Playbook uses git based collection to interact with DuckGoGo search, having in a requirements.yml public collection. You will see how the pipeline protects from such configurations. Some plays can't be used in check mode due to some reasons. Pipeline provides possibility skip the check mode.

This example uses GitHub pull request interaction assuming you are familiar with this interface. Look at day2-ops1 description for details.

### Goals

* install collection
* familiarize with galaxy firewall
* pipeline control to skip check mode

### CLI

```bash
cd day-2_ops2
ansible-galaxy install -r requirements.yml 
```

In the first step execute the playbook at the command line in a check mode.

```bash
ansible-playbook duck.yml --check
```

to see critical errors. This play does not comply to Ansible requirements. Running play in a regular mode gives the proper response.

```bash
ansible-playbook duck.yml
```

Check mode is a powerful Ansible capability to validate changes made by the playbook, without making any changes. The dry-run is powerful, however available only for properly written playbooks. Exemplary `myorg.publicapi.duckduckgo` role does not comply to Ansible standards, what may happen to your code. The pipeline makes it possible to skip `check`.

### Pipeline


Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateram GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops1. Add your name or other unique string the branch name.

2. Change variable file

```bash
QUERY="Hello World!"
jq --arg query "$QUERY" '.duckduckgo_query = $query' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json
jq --arg date "$(date)" '.timestamp = $date' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json 
```

3. commit with message "trigger day-2_ops2"

4. push branch

5. create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to notice that the plan operation is being executed.

```text
terrateam plan: day-2_ops2 default Waiting for status to be reported — Running
```

Once it's completed click on `Expand for plan output details` under pull request conversation comment's `Terrateam Plan Output` to see ansible execution plan.

```text
Ansible Execution Context
━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Playbook
━━━━━━━━━━━
duck.yml

✅ Ansible Ping
━━━━━━━━━━━━━━━
(none)

✅ Ansible Playbook Check
━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ****************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] *****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] *********
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload] *********************
fatal: [localhost]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: Unable to look up a name or access an attribute in template string ({{ ddg.json | default(ddg.content | from_json) }}).\nMake sure your variable name does not contain invalid characters like '-': the JSON object must be str, bytes or bytearray, not AnsibleUndefined. the JSON object must be str, bytes or bytearray, not AnsibleUndefined. Unable to look up a name or access an attribute in template string ({{ ddg.json | default(ddg.content | from_json) }}).\nMake sure your variable name does not contain invalid characters like '-': the JSON object must be str, bytes or bytearray, not AnsibleUndefined. the JSON object must be str, bytes or bytearray, not AnsibleUndefined\n\nThe error appears to be in '/github/home/.ansible/collections/ansible_collections/myorg/publicapi/roles/duckduckgo/tasks/main.yml': line 18, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Normalize JSON payload\n  ^ here\n"}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=1    skipped=1    rescued=0    ignored=0   

⚠️ warnings & errors
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that
the implicit localhost does not match 'all'

🗄️ Inventory file
━━━━━━━━━━━━━━━━━
(none)

🗄️ ansible.cfg file
━━━━━━━━━━━━━━━━━━━
(none)

🗄️ requirements file
━━━━━━━━━━━━━━━━━━━━
---
collections:
  - name: collections/ansible_collections/myorg/publicapi/
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.1.2
roles:
  []
```

In the execution plan you see failure of one of tasks, as the API call was skipped in a check mode, and there was no data to process. We will fix it. Ypu see warnings from playbook execution - the same as in CLI mode. Inventory and ansible.cfg were not provided, what is indicated. Finally you see requirements.yml file, with `roles:[]`, what may be surprising. It's side effect of galaxy firewall processing.

As the code is not dry-run compliant, let's disable check mode at the pipeline using ansible_piepline.yml control file.

```bash
cat > ansible_piepline.yml <<EOF
---
ansible_piepline:
  control:
    skip_check: false
EOF
```

Commit the change with message "dry run mode disable", and push, to notice that the pipeline is  triggered. Wait for the new plan.

```text

```

### Summary

