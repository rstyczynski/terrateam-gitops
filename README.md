# Terrateam Ansible engine

This project integrates Ansible automation into the Terrateam infrastructure-as-code workflow engine. The primary goal is to enable teams to manage both Terraform and Ansible operations seamlessly within Terrateam, supporting layered and multi-stage workflows across different environments and workspaces.

Preliminary capabilities include:

- Custom workflow definitions for Ansible playbooks, including init, plan, diff, and apply stages.

- Ansible config, galaxy install, and inventory support.

- Ansible apply based on static context, discovered in plan phase.

- Support for directory-based and workspace-based triggers, allowing fine-grained control over when Ansible code is executed.

- Support for layered runs and workspace-specific Ansible execution contexts.

- Debug and output hooks for enhanced visibility during CI/CD runs.

This setup is designed to help teams automate complex infrastructure and configuration management tasks, leveraging both Terraform and Ansible in a unified, auditable pipeline.

## Examples

- **day-2_ops1**: Demonstrates a basic Ansible playbook that performs a series of simple tasks on a localhost host reading parameters from a variable file.

- **day-2_ops2**: Demonstrates gathering collection from a git source using requirements files.  

- **day-2_ops3**: Demonstrates use of inventory.ini to provide host name and play variable.

- **day-2_ops4**: Demonstrates use of ansible.cfg to control ansible execution context.

- **terraform/day-1_cfg**: Contains the Terraform configuration for initial (Day 1) infrastructure provisioning, such as creating VMs, networks, or storage, which serves as the foundation for subsequent Ansible-driven Day 2 operations.


## Ansible engine scripts

## Output reception from Terraform

TODO

## Ansible output persistence

TDO
