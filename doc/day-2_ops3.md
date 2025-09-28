## day-2_ops3

### Goals

* use inventory.ini
* install collections with required git tag

### CLI

To eliminate Dry Run issues we observed in previous example, the duck query role was updated to be compatible with check mode and tagged with 0.2.1 version tag. This change is reflected in `requirements.yml` file.

```yml
---
collections:
  - name: myorg's publicapi
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.2.1
```

Inventory file in this example defines host logical name, and provides variable value for the play. Using inventory for localhost execution eliminates host related warnings, and open possibility to define host and group level variables.

```ini
[duck_api]
localhost ansible_connection=local

[duck_api:vars]
duckduckgo_query="Led Zeppelin"
```

Having both files in place let's install dependencies and run the play.

```bash
cd day-2_ops3
ansible-galaxy install -r requirements.yml 
ansible-playbook duck.yml -i inventory.ini --check
ansible-playbook duck.yml -i inventory.ini
```

Note that after the fix, the play works in check mode in same way as in regular mode as it does not change anything just loading data from remote API and displaying it.

```text
PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ***********************************************

TASK [Gathering Facts] ****************************************************************************************
[WARNING]: Host 'localhost' is using the discovered Python interpreter at '/Users/rstyczynski/projects/terrateam-gitops/.venv/bin/python3.13', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.19/reference_appendices/interpreter_discovery.html for more information.
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] ************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] ****************************************
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
localhost                  : ok=8    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

### Pipeline

Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops3. Add your name or other unique string the branch name.

2. Change any file; here additional timestamp argument is added just to trigger the pipeline.

```bash
sed $'/^\\[duck_api:vars\\]/a\\\ntimpastamp='"$(date)"$'\n' inventory.ini > /tmp/inventory.ini
mv /tmp/inventory.ini inventory.ini
```

3. commit with message "trigger day-2_ops3"

4. push branch

5. create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

```text
terrateam plan: day-2_ops3 default Waiting for status to be reported — Running
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

TASK [Gathering Facts] *********************************************************
ok: [localhost]

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
localhost                  : ok=8    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   

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
        timpastamp: Sun Sep 28 13:19:15 CEST 2025

🗄️ ansible.cfg file
━━━━━━━━━━━━━━━━━━━
(none)

🗄️ requirements file
━━━━━━━━━━━━━━━━━━━━
---
collections:
  - name: myorg's publicapi
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.2.1
roles:
  []
```

Noe the plan is almost complete, having:

* playbook name
* ping section
* play output
* inventory file
* requirements file

Notice the plan converted to yaml format - it's a side effect of capturing inventory state into the plan. The inventory whatever format it's provided e.g. dynamic plugin is converted to static plan to be used during final apply. It prevents from unexpected changes when execution context is changed between plan and apply e.g. some tags were reassigned to compute instances.

Interesting is that the plan section switched here from `(none)` as now the `localhost` was registered with connection type `local` and Ansible was able to execute `ping` module. 


To execute the play send apply command to the pipeline

```bash
terrateam apply
```

Once executed you see that the play ran successfully.

```text
✅ Running ansible-playbook
━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ****************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

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
localhost                  : ok=8    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

Your playbook logic was executed, and the execution context is stored at the Terrateam server. Drop all changes, because we do not want to push them to the repository, by closing the pull request and deleting a branch.

> **Note:** After a successful apply, you will merge and delete the feature branch to ensure all related files are in the main branch. In your local repository, switch back to the main branch and pull the latest changes.

### Summary

You learnt how Ansible pipeline handled `inventory.ini` file and how to change collection version at `requirement.yml` file. The example presented minimalistic play invoking one role with simplest possible play.
