# OpenStack External Test Platform Ansible Playbook

This repository contains an Ansible playbook that will set up
and maintain an external testing platform that can be linked
to the upstream OpenStack CI platform.

It installs Jenkins, Jenkins Job Builder (JJB), the Gerrit
Jenkins plugin, and a set of scripts that make running a variety
of OpenStack integration tests easy.

## Usage

To use this playbook, [install Ansible[(http://docs.ansible.com/intro_installation.html)
using your installation method of choice.

Once installed, you can install the external testing platform by
running the `deploy.yml` Ansible playbook from this repository:

```
cd $THIS_REPO_DIR
sudo ansible-playbook -i $HOSTS_FILE playbooks/deploy.yml --ask-sudo-pass
```

`$HOSTS_FILE` should be the location of an Ansible inventory file. We
recommend storing your inventory file in a separate Git repository for
configuration data specific to your,.
