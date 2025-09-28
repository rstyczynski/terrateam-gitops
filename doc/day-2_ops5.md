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

Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

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
```

TODO: comment of the plan phase.

To execute the play send apply command to the pipeline

```bash
terrateam apply
```

Once executed you see that the play ran successfully.

```text
```

Your playbook logic was executed, and the execution context is stored at the Terrateam server. Drop all changes, because we do not want to push them to the repository, by closing the pull request and deleting a branch.

> **Note:** In regular situation, after a successful apply, you will merge and delete the feature branch to ensure all related files are in the `main`. In your local repository you will switch back to the main branch and pull the latest changes.

### Summary

