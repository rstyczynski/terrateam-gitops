## XXX

### Goals

TODO

## Configure your environment

For these exercises, you will use Ansible on your computer. You need to install Python and Ansible packages. It is considered good practice to install packages in a Python virtual environment.

Install Python 3 using your environment's preferred method. Below is the command for macOS:

```bash
brew install python3
```

In this exercise it's enough ton ensure proper python version as virtual environment will be installed by a specialized play.

### CLI

We are going to use OCI Ansible collection, however with limitation that public galaxy servers cannot be used. In this situation oci install package will be build to be installed from local source. In real situation such package will be stored on internal artifact server; for the example I'll keep the package in the repository to have access to the file from both CLI and the pipeline.

```bash
cd day-2-venv
mkdir vendor
cd vendor
git clone https://github.com/oracle/oci-ansible-collection.git
cd oci-ansible-collection
git checkout v5.5.0
ansible-galaxy collection build 
mv oracle-oci*.tar.gz ..
cd ..
rm -rf oci-ansible-collection
```

Update the `requirements.yml` file to reflect oracle.oci location. Notice file source which is permitted by galaxy firewall script.

```yml
---
collections:
  - name: myorg's publicapi utilities
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
  - name: myorg's toolchain utilities
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/toolchain
  - name: oracle.oci
    type: file
    source: vendor/oracle-oci-5.5.0.tar.gz
```

Install the dependencies.

```bash
ansible-galaxy install -r requirements.yml
```

Prepare virtual environment.

```bash
ansible-playbook venv_manager.yml
source ~/.ansible/venv/bin/activate
```

From now on, all operations will use the Python 3 virtual environment with Ansible Core 2.15.7, and OCI 2.16 which are selected in venv_manager variables. Notice limited list of Ansible collections that are available in the virtual environment.

```bash
echo $VIRTUAL_ENV
pip list
ansible-galaxy collection list
```

Having all the dependencies in place we are ready tu run the play. Notice that at this moment virtual environment may be deactivated, as python location is set in `ansible.cfg`. It's not really necessary to deactivate but brings CLI execution closer to the pipeline context.

```bash
deactivate
ansible-playbook duck.yml -i inventory.ini 
```

As expected this run executed without any errors and warnings both external API calls: DuckDuckGo and OCI.

```text
PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] *************************************************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] *************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] **************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] ******************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.json when available] *************************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload from ddg.content when json is missing] ****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Ensure ddg_json exists (empty)] **********************************************
skipping: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] **********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] *************************************************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] *****************************************************************
ok: [localhost] => {
    "msg": "The Alan Parsons Project was a British rock duo formed in London in 1975. Its core membership consisted of producer, audio engineer, musician and composer Alan Parsons, and singer, songwriter and pianist Eric Woolfson. They shared writing credits on almost all of their songs, with Parsons producing or co-producing all of the recordings, while being accompanied by various session musicians, some relatively consistently. The Alan Parsons Project released eleven studio albums over a 15-year career, the most successful ones being I Robot, The Turn of a Friendly Card and Eye in the Sky. Many of their albums are conceptual in nature and focus on science fiction, supernatural, literary and sociological themes. Among the group's most popular songs are \"I Wouldn't Want to Be Like You\", \"Games People Play\", \"Time\", \"Sirius\", \"Eye in the Sky\", and \"Don't Answer Me\"."
}

TASK [Persist role outputs] *************************************************************************************
skipping: [localhost]

TASK [Get Object Storage namespace] *****************************************************************************
ok: [localhost]

TASK [Show namespace] *******************************************************************************************
ok: [localhost] => {
    "msg": "Namespace is zr83uv6vz6na"
}

PLAY RECAP ******************************************************************************************************
localhost                  : ok=9    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```

### Pipeline

Now let's run the same in the pipeline. It's more complex as now we need to setup virtual environment.


The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateam GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/XXX. Add your name or other unique string the branch name.

2. Change variable file to provide any change.

3. Commit with message "trigger XXX"

4. Push branch

5. Create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to see that the plan operation is being executed.

```text
terrateam plan: XXX default Waiting for status to be reported — Running
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

