## XXX

### Goals

TODO

## Configure your environment

For these exercises, you will use Ansible on your computer. You need to install Python and Ansible packages. It is considered good practice to install packages in a Python virtual environment.

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

From now on, all operations will use the Python 3 virtual environment with Ansible Core 2.19.2, the latest version.

### CLI

```bash
cd day-2-venv
ansible-galaxy install -r requirements.yml
```

```bash
ansible-playbook venv_manager.yml
```

```bash
ansible-playbook duck.yml -i inventory.ini 
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

