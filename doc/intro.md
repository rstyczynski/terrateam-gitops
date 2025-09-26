# title

Working with ansible you will use the repository from your command line to execute exactly the same by the pipeline. All the exercises work on a localhost, so you do not need to configure any machines to spin the playbooks.

Exercises aims to familiarize you with the following Ansible Engine capabilities:

* CLI / pipeline user experience
* pipeline plan with ansible-playbook check mode and ping
* pipeline control for debug purposes
* pipeline control to disable ping or check
* collection install from dir/git sources
* collection install blocking public galaxy sources
* work with inventory hosts and variables
* work with ansible.cfg
* GitHub ansible engine outputs for plan stage - plan-of-work
* GitHub ansible engine outputs for apply stage - proof-of-work

## Configure your environment

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

### Goals

* execute simple playbook
* familiarize with CLI / pipeline user experience
* familiarize with GitHub ansible engine outputs for plan stage
* familiarize with GitHub ansible engine outputs for apply stage

### CLI

In the first step execute the playbook at the command line in a check mode.

```bash
cd day-2_ops1
rm -f /tmp/ansible_test_output.txt
ansible-playbook playbook.yml --check
```

to receive the following output:

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [Hello World Playbook] ********************************************************************************

TASK [Display hello message] *******************************************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Hello World at Fri Sep 26 09:33:24 CEST 2025"
}

TASK [Create a test file] **********************************************************************************
changed: [localhost]

PLAY RECAP *************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

You see from the check that the playbook is going to create file. Let's execute the play.

```bash
ansible-playbook playbook.yml 
```

to find out that the play indeed created the file:

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [Hello World Playbook] ********************************************************************************

TASK [Display hello message] *******************************************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Hello World at Fri Sep 26 09:33:24 CEST 2025"
}

TASK [Create a test file] **********************************************************************************
changed: [localhost]

PLAY RECAP *************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

As you see the playbook just reads variable file and outputs some information, reporting warnings to stderr. The fact of changing the target system is reported by a check mode. This capability us used in a plan-of-work at the pipeline.

### pipeline

Now let's run the same in the pipeline. The pipeline is triggered by a file change under a branch and a pull request, what is controlled by a Terrateram GitHub extension. To trigger the pipeline execute following steps:

1. Create a branch with name: your_name/day-2_ops1. Add your name or other unique string the branch name.

2. Change variable file

```bash
MESSAGE="Hello World at $(date)!"
jq --arg msg "$MESSAGE" '.message = $msg' vars.json > /tmp/tmp.json && mv /tmp/tmp.json vars.json 
```
3. commit with message "trigger day-2_ops1"

4. push branch

5. create a pull request

Open the pull request at https://github.com/rstyczynski/terrateam-gitops to notice that the plan operation is being executed.

```text
terrateam plan: day-2_ops1 default Waiting for status to be reported — Running
```

Once it's completed click on `Expand for plan output details` under pull request conversation comment's `Terrateam Plan Output` to see ansible execution plan.

```text
Ansible Execution Context
━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Playbook
━━━━━━━━━━━
playbook.yml

✅ Ansible Ping
━━━━━━━━━━━━━━━
(none)

✅ Ansible Playbook Check
━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [Hello World Playbook] ****************************************************

TASK [Display hello message] ***************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Hello World at Fri Sep 26 09:33:24 CEST 2025"
}

TASK [Create a test file] ******************************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

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
(none)
```

At the plan you see playbook name, ping test of target hosts. Playbook execution in the check mode is a special mode in Ansible that shows changes to be done at the target host, without actually making them at this stage. Check mode informs what will be done during apply. Here you see that check mode output is exactly the same as from CLI.

Moreover you see inventory, ansible.cfg, and galaxy install's requirements file. This example just executes simple playbook, so all other elements are presented as `(none)`. Notice `warning` sections that may appear to inform about warning and error messages reported by each element of the plan stage. For playbooks this information is collected from stdout, and is presented at another section, what is the only difference from CLI execution.

After review of the plan-of-work, accept the execution by adding `terrateam apply` to pull request conversation comment to notice that operation is being executed.

```text
terrateam apply: day-2_ops1 default Waiting for status to be reported — Running
```

Once the apply is completed click on`Expand for apply output details` under `Terrateam Apply Output` to see the playbook execution output.

```text
✅ Running ansible-playbook
━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [Hello World Playbook] ****************************************************

TASK [Display hello message] ***************************************************
ok: [localhost] => {
    "msg": "Hello World from Ansible! Message: Hello World at Fri Sep 26 09:33:24 CEST 2025"
}

TASK [Create a test file] ******************************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

⚠️ warnings & errors
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
```

Now you can merge and delete the branch. Your playbook applied changes at target systems, the execution context is stored at the Terrateam server, and all related files are in the main branch.

### summary

You executed simple playbook using check based approach. You did the same form a CLI and the pipeline.

Note that variable and the playbook itself are not presented at the plan document being part of the repository. Reviewer looking at the plan in case of required verification should validate content of the playbook and variables. Variables are of course partially visible in the check execution output. 

## day-2_ops2

