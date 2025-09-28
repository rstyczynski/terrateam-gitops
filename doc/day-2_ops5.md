## day-2_ops5

### Goals

* select play to be executed using `ansible_pipeline.yml` control file
* filter public galaxy from `requirements.yml` file
* introduction to use of Oracle OCI collection 

## Configure your environment

As exercises use Ansible on you computer, you need to install python, and Ansible packages. It's always the good practice to install packages in python virtual environment.

Install python3 using your environment technique. Here code for MacOS.

```bash
brew install python3
```

Having python ready, create virtual environment, and install packages. Note that all the operations are done in repository root. Note that .venv is added to .gitignore, so will be not added to any commits.

```bash
python3 -m venv .venv 
source .venv/bin/activate 
pip install --upgrade pip 
pip install "ansible-core==2.19.2" 
```

Now all operations are done using python 3 virtual environment with ansible core 2.19.2 which is the latest version.

### CLI

The CLI uses OCI and it's assumed you have OCI access configured. To validate execute below command

```bash
oci os ns get && pip install oci
```

, expecting the answer showing namespace id and output from oci package install process.

```json
{
  "data": "zr83uv6vz6na"
}
Collecting oci
  Using cached oci-2.160.2-py3-none-any.whl.metadata (5.8 kB)
  (...)
```

If above works - that's great. If not - no worries as anyway in the pipeline mode OCI access will be disabled.

Run procedure installs oci python SDK, configures ansible to use python from virtual environment, to Ansible have access to installed OCI package, installs dependencies including oci collection, and runs `duck_bobdylan.yml` play that invokes OCI module.

```bash
cd day-2_ops5
pip install oci
sed "s|^interpreter_python.*|interpreter_python = $(which python)|" ansible.cfg > /tmp/ansible.cfg
mv /tmp/ansible.cfg ansible.cfg

ansible-galaxy install -r requirements.yml 
ansible-playbook duck_bobdylan.yml -i inventory.ini
```

Ansible output does everything what was expected.

```text
PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ***********************************************

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
    "msg": "Bob Dylan is an American singer-songwriter. Described as one of the greatest songwriters of all time, Dylan has been a major figure in popular culture over his 68-year career. With an estimated 125 million records sold worldwide, he is one of the best-selling musicians. Dylan added increasingly sophisticated lyrical techniques to the folk music of the early 1960s, infusing it \"with the intellectualism of classic literature and poetry\". His lyrics incorporated political, social, and philosophical influences, defying pop music conventions and appealing to the burgeoning counterculture. Dylan was born in St. Louis County, Minnesota. He moved to New York City in 1961 to pursue a career in music. His 1962 debut album, Bob Dylan, containing traditional folk and blues material, was followed by his breakthrough album: The Freewheelin' Bob Dylan, which included \"Girl from the North Country\" and \"A Hard Rain's a-Gonna Fall\", adapting older folk songs."
}

TASK [Persist role outputs] ***********************************************************************************
skipping: [localhost]

TASK [Get Object Storage namespace] ***************************************************************************
ok: [localhost]

TASK [Show namespace] *****************************************************************************************
ok: [localhost] => {
    "msg": "Namespace is zr83uv6vz6na"
}

PLAY RECAP ****************************************************************************************************
localhost                  : ok=9    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```

### Pipeline

Now let's run the same in the pipeline. the situation is much different as now we have more than one play in the directory, and it's mandatory to instruct the pipeline which play to use, what is done using `ansible_piepline.yml` control file.

```yaml
---
ansible_piepline:
  ansible_playbook: duck_bobdylan.yml
```

The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops5. Add your name or other unique string the branch name.

2. Change vars.json file; here additional timestamp argument is added just to trigger the pipeline.

```bash
jq --arg date "$(date)" '.timestamp = $date' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json
```

3. Commit with message "trigger day-2_ops5"

4. Push branch

5. Create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

```text
terrateam plan: day-2_ops5 default Waiting for status to be reported — Running
```

Once it's completed click on `Expand for plan output details` under pull request conversation comment's `Terrateam Plan Output` to see ansible execution plan.

```text
Ansible Execution Context
━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Playbook
━━━━━━━━━━━
duck_bobdylan.yml

✅ Ansible Ping
━━━━━━━━━━━━━━━
localhost | FAILED! => {
    "changed": false,
    "module_stderr": "/bin/sh: 1: /Users/rstyczynski/projects/terrateam-gitops/.venv/bin/python: not found\n",
    "module_stdout": "",
    "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error",
    "rc": 127
}

✅ Ansible Playbook Check
━━━━━━━━━━━━━━━━━━━━━━━━━
(none)

⚠️ warnings & errors
ERROR! couldn't resolve module/action 'oracle.oci.oci_object_storage_namespace_facts'. This often indicates a misspelling, missing collection, or incorrect module path.

The error appears to be in '/github/workspace/day-2_ops5/duck_bobdylan.yml': line 11, column 7, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

  tasks:
    - name: Get Object Storage namespace
      ^ here

🗄️ Inventory file
━━━━━━━━━━━━━━━━━
all:
  children:
    duck_api:
      hosts:
        localhost:
          ansible_connection: local

🗄️ ansible.cfg file
━━━━━━━━━━━━━━━━━━━
[defaults]
gathering = explicit
interpreter_python = /Users/rstyczynski/projects/terrateam-gitops/.venv/bin/python

🗄️ requirements file
━━━━━━━━━━━━━━━━━━━━
---
collections:
  - name: collections/ansible_collections/myorg/publicapi/
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.2.1
  # BLOCKED by galaxy_firewall: name: oracle.oci
  # BLOCKED by galaxy_firewall: version: '>=5.4.0'
roles:
  []

⚠️ warnings & errors
Warning: Requirements file uses public sources. Public sources removed.
```

You see on the execution plan that the play file was selected properly. Ping step presents errors related to wrong python location. Check presents errors related to missing module, what is expected, as galaxy firewall filtered out public galaxy sources, what is visible in `requirements file` section.

```text
---
collections:
  - name: collections/ansible_collections/myorg/publicapi/
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.2.1
  # BLOCKED by galaxy_firewall: name: oracle.oci
  # BLOCKED by galaxy_firewall: version: '>=5.4.0'
roles:
  []

⚠️ warnings & errors
Warning: Requirements file uses public sources. Public sources removed.
```

Your playbook logic totally failed, what was expected and gives you valuable debug information. More debug may be requested by setting debug levels in `ansible_piepline.yml` control file.

```yaml
---
ansible_piepline:
  ansible_playbook: duck_bobdylan.yml
  debug:
    diff: true
    plan: true
```

Even with the failure, the execution context is still stored at the Terrateam server for further analysis. Drop all changes, because we do not want to push them to the repository, by closing the pull request and deleting a branch.

### Summary

Thus exercise presented how to set play filename in case of having more than one plays in the directory. You learnt that galaxy firewall filters public galaxy sources, and you learnt how ping, and stederr presentation, and additional debug flags helps in diagnosing failures.