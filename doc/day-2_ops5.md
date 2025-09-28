## day-2_ops5

### Goals

* Select the play to be executed using the `ansible_pipeline.yml` control file.
* Filter public Galaxy sources from the `requirements.yml` file.
* Introduction to using the Oracle OCI collection.

## Configure your environment

For these exercises, you will use Ansible on your computer. You need to install Python and Ansible packages. It is always good practice to install packages in a Python virtual environment.

Install Python 3 using your environment's preferred method. Below is the command for macOS:

```bash
brew install python3
```

Once Python is ready, create a virtual environment and install the required packages. Note that all operations are done in the repository root. Also, `.venv` is added to `.gitignore`, so it will not be included in any commits.

```bash
python3 -m venv .venv 
source .venv/bin/activate 
pip install --upgrade pip 
pip install "ansible-core==2.19.2" 
```

Now all operations are performed using the Python 3 virtual environment with Ansible Core 2.19.2, which is the latest version.

### CLI

The CLI uses OCI, and it is assumed you have OCI access configured. To validate, execute the following command:

```bash
oci os ns get && pip install oci
```

You should see a response showing the namespace ID and the output from the OCI package installation process, for example:

```json
{
  "data": "zr83uv6vz6na"
}
Collecting oci
  Using cached oci-2.160.2-py3-none-any.whl.metadata (5.8 kB)
  (...)
```

If the above works, that's great. If not, no worries, as OCI access will be disabled in pipeline mode anyway.

The procedure below installs the OCI Python SDK, configures Ansible to use Python from the virtual environment (so Ansible has access to the installed OCI package), installs dependencies including the OCI collection, and runs the `duck_bobdylan.yml` play that invokes the OCI module.

```bash
cd day-2_ops5
pip install oci
sed "s|^interpreter_python.*|interpreter_python = $(which python)|" ansible.cfg > /tmp/ansible.cfg
mv /tmp/ansible.cfg ansible.cfg

ansible-galaxy install -r requirements.yml 
ansible-playbook duck_bobdylan.yml -i inventory.ini
```

The Ansible output performs everything as expected.

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

Now let's run the same in the pipeline. The situation is quite different, as we now have more than one play in the directory, and it is mandatory to instruct the pipeline which play to use. This is done using the `ansible_pipeline.yml` control file.

```yaml
---
ansible_pipeline:
  ansible_playbook: duck_bobdylan.yml
```

The pipeline is triggered by a file change under a branch and a pull request, controlled by a Terrateam GitHub extension. To trigger the pipeline, follow these steps:

1. Create a branch named: your_name/day-2_ops5. Add your name or another unique string to the branch name.

2. Modify the `vars.json` file; here, an additional timestamp argument is added just to trigger the pipeline.

```bash
jq --arg date "$(date)" '.timestamp = $date' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json
```

3. Commit with the message "trigger day-2_ops5".

4. Push the branch.

5. Create a pull request.

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

```text
terrateam plan: day-2_ops5 default Waiting for status to be reported — Running
```

Once completed, click on `Expand for plan output details` under the pull request conversation comment's `Terrateam Plan Output` to see the Ansible execution plan.

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

You can see in the execution plan that the play file was selected properly. The Ping step shows errors related to the wrong Python location. The check step presents errors related to a missing module, which is expected because the Galaxy firewall filtered out public Galaxy sources, as visible in the `requirements file` section.

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

Your playbook logic completely failed, which was expected and provides valuable debug information. More debugging can be enabled by setting debug levels in the `ansible_pipeline.yml` control file.

```yaml
---
ansible_pipeline:
  ansible_playbook: duck_bobdylan.yml
  debug:
    diff: true
    plan: true
```

Even with the failure, the execution context is still stored on the Terrateam server for further analysis. Discard all changes because we do not want to push them to the repository by closing the pull request and deleting the branch.

### Summary

This exercise demonstrated how to specify the play filename when there is more than one play in the directory. You learned that the Galaxy firewall filters public Galaxy sources, and you saw how Ansible Ping errors and stderr output help diagnose failures. Additional debug flags in the control file can provide further insight.
