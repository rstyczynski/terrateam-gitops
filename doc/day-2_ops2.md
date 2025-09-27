## day-2_ops2

Ansible Engine is provided with capability to protect pipeline from installing collections from public sources allowing only dir and git ones. Playbook uses git based collection to interact with DuckGoGo search, having in a requirements.yml public collection. You will see how the pipeline protects from such configurations. Some plays can't be used in check mode due to some reasons. Pipeline provides possibility skip the check mode.

This example uses GitHub pull request interaction assuming you are familiar with this interface. Look at day2-ops1 description for details.

### Goals

* install collection
* familiarize with galaxy firewall
* pipeline control to skip check mode

### CLI

```bash
cd day-2_ops2
ansible-galaxy install -r requirements.yml 
```

In the first step execute the playbook at the command line in a check mode.

```bash
ansible-playbook duck.yml --check
```

to see critical errors. This play does not comply to Ansible requirements. 

Running play in regular mode gives xxx

```bash
ansible-playbook duck.yml
```

### Pipeline

```text
Ansible Execution Context
━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Playbook
━━━━━━━━━━━
duck.yml

✅ Ansible Ping
━━━━━━━━━━━━━━━
(none)

✅ Ansible Playbook Check
━━━━━━━━━━━━━━━━━━━━━━━━━
(none)

🗄️ Inventory file
━━━━━━━━━━━━━━━━━
(none)

🗄️ ansible.cfg file
━━━━━━━━━━━━━━━━━━━
(none)

🗄️ requirements file
━━━━━━━━━━━━━━━━━━━━
---
collections:
  - name: collections/ansible_collections/myorg/publicapi/
    type: git
    source: https://github.com/rstyczynski/ansible-collection-howto.git#/collections/ansible_collections/myorg/publicapi
    version: 0.1.2
  # BLOCKED by galaxy_firewall: name: microsoft.ad
  # BLOCKED by galaxy_firewall: version: 1.9.2
roles:
  []

⚠️ warnings & errors
Warning: Requirements file uses public sources. Public sources removed.
```


```text
✅ Running ansible-playbook
━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLAY [DuckDuckGo Instant Answer via Ansible (using collection)] ****************

TASK [myorg.publicapi.duckduckgo : Validating arguments against arg spec 'main' - Query DuckDuckGo] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Validate inputs (explicit)] *****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Call DuckDuckGo Instant Answer API] *********
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Normalize JSON payload] *********************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Build final answer (Answer -> AbstractText -> top 3 RelatedTopics)] ***
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Store role outputs as facts] ****************
ok: [localhost]

TASK [myorg.publicapi.duckduckgo : Show result] ********************************
ok: [localhost] => {
    "msg": "Richard Wagner A German composer, theatre director, polemicist, and conductor who is chiefly known for his...\\nWagner Group A Russian state-funded private military company controlled until 2023 by Yevgeny Prigozhin, a...\\nWagner College A private liberal arts college in Staten Island, New York City."
}

TASK [Persist role outputs] ****************************************************
skipping: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=7    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

### Summary

