# Experimental capabilities

## TODO: Commit files in current repo / new branch from main

There may be a need to update file in repository as part of the workflow, that will continue once depended change is approved, applied and merged.

When there is a need to update file in the same repo or different:

1. checkout repo in new directory
2. create a branch
3. change a file
4. commit the change
5. create PR
6. save PR number

## FAILED: Commit files in current repo / new branch form the current one

When branch is created from another branch, PR works well, however after secondary PR close, the preliminary is closed as well. It's not expected, however it's a consequence of modifying Terrateam execution context.

## FAILED: Commit files in current repo / current branch

Ansible Terrateam kit comes with a script that commits files changed in current repository using Terrateam token available in the environment.

```bash
echo "Hello World by Ansible init!" > ${ANSIBLE_ROOT}/hello.txt
export COMMIT_MSG="hello.txt file updated"
${TERRATEAM_ROOT}/.terrateam/shared/commit.sh
```

To be able to write files to the current repository two configurations must be completed:

1. GitHub repository must enable workflow to make changes

`github.com` → `repository` → `Settings` → `Actions` → `General` → `Workflow permissions`  → <kbd>●</kbd> **Read and write permissions**

2. Terrateam workflow definition must be updated with write permission for a terraform job

`.github/workflows/terrateam.yml` → `jobs` → `terrateam` → `permissions` → **contents: write**

Problem: changing file in the current PR makes Terrateam engine to run workflow in the same PR, even for different directory. Terrateam seems to be lost with workflows, even assuming that it's a layered run.

Solution: Create new branch out of main, and create PR for this. Under this new PR changes should be applied.

