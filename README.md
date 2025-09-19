## more packages?

https://docs.terrateam.io/integrations/installing-packages/

## dir

### env

TODO: Ansible apply
CWD: /github/workspace/terraform/day-1_cfg
TERRATEAM_ROOT: /github/workspace
TERRATEAM_DIR: terraform/day-1_cfg
TERRATEAM_WORKSPACE: default

### workflow

when dir/workflow is changed all workflows are triggered

## workspace

### env with workspace cfg

CWD: /github/workspace/day-2_ops3
TERRATEAM_DIR: day-2_ops3
TERRATEAM_WORKSPACE: dev
TERRATEAM_ROOT: /github/workspace

### workflows

TODO workspace file change detection does not work
TODO workspace tags do not influence engine. engine is taken from dir tag
