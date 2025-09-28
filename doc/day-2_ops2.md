## day-2_ops2

Ansible Engine is provided with capability to protect pipeline from installing collections from public sources allowing only `dir` and `git` sources. Playbook uses git based collection to interact with DuckDuckGo search, with a collection declared in `requirements.yml`. Some plays can't be used in check mode due to some reasons. Pipeline provides possibility to skip the check mode.

### Goals

* install collections
* pipeline control to skip check mode

### CLI

The play uses DuckDuckGo query role that is part of `myorg.publicapi` collection. The dependency is registered in `requirements.yml` file.

```yaml
---
collections:
  - name: myorg.publicapi
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.1.2
```

and installed using regular ansible command.

```bash
cd day-2_ops2
ansible-galaxy install -r requirements.yml 
```

Having the collection in place, let's execute the playbook at the command line in a dry-run mode to estimate changes that are planned to be done.

```bash
ansible-playbook duck.yml --check
```

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ***********************************************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] ************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] ****************************************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload] ****************************************************
[ERROR]: Task failed: Finalization of task args for 'ansible.builtin.set_fact' failed: Error while resolving value for 'ddg_json': object of type 'dict' has no attribute 'content'

Task failed.
Origin: /Users/rstyczynski/.ansible/collections/ansible_collections/myorg/publicapi/roles/duckduckgo/tasks/main.yml:18:3

16   register: ddg
17
18 - name: Normalize JSON payload
     ^ column 3

<<< caused by >>>

Finalization of task args for 'ansible.builtin.set_fact' failed.
Origin: /Users/rstyczynski/.ansible/collections/ansible_collections/myorg/publicapi/roles/duckduckgo/tasks/main.yml:19:3

17
18 - name: Normalize JSON payload
19   set_fact:
     ^ column 3

<<< caused by >>>

Error while resolving value for 'ddg_json': object of type 'dict' has no attribute 'content'
Origin: /Users/rstyczynski/.ansible/collections/ansible_collections/myorg/publicapi/roles/duckduckgo/tasks/main.yml:20:15

18 - name: Normalize JSON payload
19   set_fact:
20     ddg_json: "{{ ddg.json | default(ddg.content | from_json) }}"
                 ^ column 15

fatal: [localhost]: FAILED! => {"changed": false, "msg": "Task failed: Finalization of task args for 'ansible.builtin.set_fact' failed: Error while resolving value for 'ddg_json': object of type 'dict' has no attribute 'content'"}

PLAY RECAP ****************************************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=1    skipped=1    rescued=0    ignored=0  
```

to see critical errors. This play does not comply with Ansible requirements. Running play in a regular mode gives the proper response.

```bash
ansible-playbook duck.yml
```

The check mode failed, but in this play it does not break from regular run, which gives proper results.

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ***********************************************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] ************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] ****************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload] ****************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ***********************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ***************************************************************
ok: [localhost] => {
    "msg": "Wolfgang Amadeus Mozart A prolific and influential composer of the Classical period.\\nConstanze Mozart A German soprano, later a businesswoman.\\nLeopold Mozart A German composer, violinist, and music theorist."
}

TASK [Persist role outputs] ***********************************************************************************
skipping: [localhost]

PLAY RECAP ****************************************************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
```

### Pipeline

Check mode is a powerful Ansible capability to validate changes made by the playbook, without making any changes. The dry-run is powerful, however available only for properly written playbooks. Exemplary `myorg.publicapi.duckduckgo` role does not comply with Ansible standards, what may happen to your code. The pipeline makes it possible to skip `check`.

Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops2. Add your name or other unique string the branch name.

2. Change variable file to provide any change, here additional timestamp argument is added just to trigger the pipeline.

```bash
jq --arg date "$(date)" '.timestamp = $date' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json 
```

3. commit with message "trigger day-2_ops2"

4. push branch

5. create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

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

In the execution plan you see failure of one of tasks, as the API call was skipped in a check mode, and there was no data to process. We will fix it. You see warnings from playbook execution - the same as in CLI mode. Inventory and ansible.cfg were not provided, what is indicated. Finally you see requirements.yml file, with `roles:[]`, what may be surprising. It's side effect of galaxy firewall processing.

As the code is not dry-run compliant, let's disable check mode at the pipeline using ansible_pipeline.yml control file.

```bash
cat > ansible_pipeline.yml <<EOF
---
ansible_piepline:
  control:
    skip_check: true
EOF
```

Commit the change with message "dry run mode disable", and push, to notice that the pipeline is triggered. Wait for the new plan with check mode step disabled.

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
(none)

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

To execute the play send apply command to the pipeline

```bash
terrateam apply
```

Once executed you see that the play ran successfully.

```text
✅ Running ansible-playbook
━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ****************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] *****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] *********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload] *********************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ********************************
ok: [localhost] => {
    "msg": "Wolfgang Amadeus Mozart A prolific and influential composer of the Classical period.\\nConstanze Mozart A German soprano, later a businesswoman.\\nLeopold Mozart A German composer, violinist, and music theorist."
}

TASK [Persist role outputs] ****************************************************
skipping: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

Your playbook logic was executed, and the execution context is stored at the Terrateam server. Drop all changes, because we do not want to push them to the repository, by closing the pull request and deleting a branch.

> **Note:** In regular situation, after a successful apply, you will merge and delete the feature branch to ensure all related files are in the `main`. In your local repository you will switch back to the main branch and pull the latest changes.

### Summary

You learnt that the pipeline automatically installs collections, and how to control potentially required skip of the dry-run mode using `ansible_pipeline.yml` control file.
