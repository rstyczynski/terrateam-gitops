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
