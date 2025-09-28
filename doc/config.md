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
pip install ansible 
```
