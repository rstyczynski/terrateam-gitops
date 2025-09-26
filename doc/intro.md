# title

Working with ansible you will use the repository directory from your command line to execute exactly the same by the pipeline. All the exercises work on localhost, so you do not need to configure any machines to spin the playbooks.

## Configure yu environment

As exercises use ansible on you computer, you need to install python, and Ansible packages. It's always the good practice to install packages in python virtual environment.

Install python3 using your environment technique. Here code for MacOS.

```bash
brew install python3
```

Having python ready, create virtual environment, and install packages. Note that all the operations are done in repository root. Note that .venv is added to .gitignore, so will be not added to any commits.

```bash
python3 -m venv .venv 
source .venv/bin/activate 
pip install --upgrade pip 
pip install ansible 
```

## day-2_ops1

Execute the playbook at the command line.

```bash
ansible-playbook playbook.yml 
```

Playbook just reads variable file and outputs some information.

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
[WARNING]: Found variable using reserved name 'environment'.
Origin: <unknown>

environment


PLAY [Hello World Playbook] ********************************************************************************

TASK [Display hello message] *******************************************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Welcome to Terrateam Ansible Integration!"
}

TASK [Display environment info] ****************************************************************************
ok: [localhost] => {
    "msg": "Environment: [], Version: 1.0.36"
}

TASK [Create a test file] **********************************************************************************
ok: [localhost]

TASK [Show summary] ****************************************************************************************
ok: [localhost] => {
    "msg": "Playbook execution completed successfully!\n- Message: Welcome to Terrateam Ansible Integration!\n- Environment: []\n- Version: 1.0.36\n- File created: True\n"
}

PLAY RECAP *************************************************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

Now let's run the same in the pipeline:

1. Create a branch with name: $your_name/day-2_ops1

2. Change variable file

```bash
MESSAGE="Hello World at $(date)"
jq --arg msg "$MESSAGE" '.message = $msg' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json 
```

3. commit with message "trigger day-2_ops1"

4. push branch

5. create pul request

Open pull request at GitHub to notice that the plan operation is being executed.

```
terrateam plan: day-2_ops1 defaultWaiting for status to be reported — Running
```

Once completed click in comments on `Expand for plan output details` under `Terrateam Plan Output` to see ansible execution plan.

```text
Ansible will be executed in the following context:
---
ansible_execution_context:
  ANSIBLE_PLAYBOOK: "playbook.yml"
  
  ANSIBLE_PLAYBOOK_ERROR: ""
  
  ANSIBLE_INVENTORY:
  
  ANSIBLE_CUSTOM_CFG:
  
  ANSIBLE_CUSTOM_REQUIREMENTS:
  
  ANSIBLE_CUSTOM_REQUIREMENTS_EFFECTIVE:
  
  ANSIBLE_CUSTOM_REQUIREMENTS_ERROR: ""
  
  ENV:
    ANSIBLE_ROOT: "/github/workspace/day-2_ops1"
    TERRATEAM_DIR: "day-2_ops1"
    TERRATEAM_WORKSPACE: "default"
    TERRATEAM_ROOT: "/github/workspace"
```

At the plan you see that `playbook.yml` will be executed in `/github/workspace/day-2_ops1` directory. Accept execution by adding `terrateam apply` to pull request conversation comment to notice that operation is being executed.

```
terrateam apply: day-2_ops1 default - running
```

Once the apply is completed click in comments on `Expand for apply output details` under `Terrateam Apply Output` to see playbook output and section with stderr output.

```
Running ansible-playbook
========================

PLAY [Hello World Playbook] ****************************************************

TASK [Display hello message] ***************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Welcome to Terrateam Ansible Integration!"
}

TASK [Display environment info] ************************************************
ok: [localhost] => {
    "msg": "Environment: [], Version: 1.0.36"
}

TASK [Create a test file] ******************************************************
changed: [localhost]

TASK [Show summary] ************************************************************
ok: [localhost] => {
    "msg": "Playbook execution completed successfully!\n- Message: Welcome to Terrateam Ansible Integration!\n- Environment: []\n- Version: 1.0.36\n- File created: True\n"
}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


Errors and warnings (stderr):
=============================
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that
the implicit localhost does not match 'all'
[WARNING]: Found variable using reserved name: environment
```

Now you can merge and delete the branch. Your setting are now in the main branch.