## day-2_ops4

### Goals

* use `ansible.cfg` to configure Ansible execution context

### CLI

To speed up the execution I'll disable fact collection, and to make it invisible for the play, I'll do it using `ansible.cfg`.

```ini
[defaults]
gathering = explicit
```

Let's run the play to notice that 'Gathering Facts' task is not executed anymore.

```bash
cd day-2_ops4
ansible-galaxy install -r requirements.yml 
ansible-playbook duck.yml -i inventory.ini
```

Notice python related warning that moved to the moment of calling Duck API - it's the first moment when python on managed node is executed, and indeed 'Gathering Facts' task is no at the execution report.

```text
PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ***********************************************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] ************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] ****************************************
[WARNING]: Host 'localhost' is using the discovered Python interpreter at '/Users/rstyczynski/projects/terrateam-gitops/.venv/bin/python3.13', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.19/reference_appendices/interpreter_discovery.html for more information.
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.json when available] ***********************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.content when json is missing] **************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Ensure ddg_json exists (empty)] ********************************************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ***********************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ***************************************************************
ok: [localhost] => {
    "msg": "Led Zeppelin were an English rock band formed in London in 1968. The band comprised vocalist Robert Plant, guitarist Jimmy Page, bassist-keyboardist John Paul Jones and drummer John Bonham. With a heavy, guitar-driven sound and drawing from influences including blues and folk music, Led Zeppelin are cited as a progenitor of hard rock and heavy metal. Among the best-selling music artists of all time, they influenced the music industry, particularly in the development of album-oriented rock and stadium rock. Led Zeppelin evolved from a previous band, the Yardbirds, and were originally named \"the New Yardbirds\". They signed a deal with Atlantic Records that gave them considerable artistic freedom. Initially unpopular with critics, they achieved all-but-unmatched commercial success with eight studio albums over ten years."
}

TASK [Persist role outputs] ***********************************************************************************
skipping: [localhost]

PLAY RECAP ****************************************************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

### Pipeline

Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops4. Add your name or other unique string the branch name.

2. Change any file; here additional timestamp argument is added just to trigger the pipeline.

```bash
sed $'/^\\[duck_api:vars\\]/a\\\ntimestamp='"$(date)"$'\n' inventory.ini > /tmp/inventory.ini
mv /tmp/inventory.ini inventory.ini
```

3. Commit with message "trigger day-2_ops4"

4. Push branch

5. Create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

```text
terrateam plan: day-2_ops4 default Waiting for status to be reported — Running
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
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

✅ Ansible Playbook Check
━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ****************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] *****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] *********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.json when available] ***
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.content when json is missing] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Ensure ddg_json exists (empty)] *************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ********************************
ok: [localhost] => {
    "msg": "Led Zeppelin were an English rock band formed in London in 1968. The band comprised vocalist Robert Plant, guitarist Jimmy Page, bassist-keyboardist John Paul Jones and drummer John Bonham. With a heavy, guitar-driven sound and drawing from influences including blues and folk music, Led Zeppelin are cited as a progenitor of hard rock and heavy metal. Among the best-selling music artists of all time, they influenced the music industry, particularly in the development of album-oriented rock and stadium rock. Led Zeppelin evolved from a previous band, the Yardbirds, and were originally named \"the New Yardbirds\". They signed a deal with Atlantic Records that gave them considerable artistic freedom. Initially unpopular with critics, they achieved all-but-unmatched commercial success with eight studio albums over ten years."
}

TASK [Persist role outputs] ****************************************************
skipping: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   

🗄️ Inventory file
━━━━━━━━━━━━━━━━━
all:
  children:
    duck_api:
      hosts:
        localhost:
          ansible_connection: local
      vars:
        duckduckgo_query: Led Zeppelin
        timestamp: Sun Sep 28 14:22:10 CEST 2025

🗄️ ansible.cfg file
━━━━━━━━━━━━━━━━━━━
[defaults]
gathering = explicit  

🗄️ requirements file
━━━━━━━━━━━━━━━━━━━━
---
collections:
  - name: collections/ansible_collections/myorg/publicapi/
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.2.1
roles:
  []
```

Now the plan is complete, having:

* playbook name
* ping section
* play output
* inventory file
* ansible.cfg
* requirements file

Notice the plan converted to yaml format - it's a side effect of capturing inventory state into the plan. The inventory whatever format it's provided e.g. dynamic plugin is converted to static plan to be used during final apply. It prevents from unexpected changes when execution context is changed between plan and apply e.g. some tags were reassigned to compute instances.

Interesting is that the plan section switched here from `(none)` as now the `localhost` was registered with connection type `local` and Ansible was able to execute `ping` module.

Plan shows `ansible.cfg` file that here is used to control fact collection, however in real situation is the powerful mean to control all aspects of Ansible execution environment.

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

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.json when available] ***
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.content when json is missing] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Ensure ddg_json exists (empty)] *************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ********************************
ok: [localhost] => {
    "msg": "Led Zeppelin were an English rock band formed in London in 1968. The band comprised vocalist Robert Plant, guitarist Jimmy Page, bassist-keyboardist John Paul Jones and drummer John Bonham. With a heavy, guitar-driven sound and drawing from influences including blues and folk music, Led Zeppelin are cited as a progenitor of hard rock and heavy metal. Among the best-selling music artists of all time, they influenced the music industry, particularly in the development of album-oriented rock and stadium rock. Led Zeppelin evolved from a previous band, the Yardbirds, and were originally named \"the New Yardbirds\". They signed a deal with Atlantic Records that gave them considerable artistic freedom. Initially unpopular with critics, they achieved all-but-unmatched commercial success with eight studio albums over ten years."
}

TASK [Persist role outputs] ****************************************************
skipping: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

The playbook logic was executed, and the execution context is stored at the Terrateam server. Drop all changes, because we do not want to push them to the repository, by closing the pull request and deleting a branch.

> **Note:** In regular situation, after a successful apply, you will merge and delete the feature branch to ensure all related files are in the `main`. In your local repository you will switch back to the main branch and pull the latest changes.

### Summary

You learnt that Ansible pipeline enables Ansible engineer to provide `ansible.cfg` to the execution context.