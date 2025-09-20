# Terrateam Ansible engine

This project integrates Ansible automation into the Terrateam infrastructure-as-code workflow engine. The primary goal is to enable teams to manage both Terraform and Ansible operations seamlessly within Terrateam, supporting layered and multi-stage workflows across different environments and workspaces.

Preliminary capabilities include:
- Custom workflow definitions for Ansible playbooks, including plan, diff, and apply stages.

- Support for directory-based and workspace-based triggers, allowing fine-grained control over when Ansible code is executed.

- Debug and output hooks for enhanced visibility during CI/CD runs.

- Early support for layered runs and workspace-specific Ansible execution contexts.

This setup is designed to help teams automate complex infrastructure and configuration management tasks, leveraging both Terraform and Ansible in a unified, auditable pipeline.
