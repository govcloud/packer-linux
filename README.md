# Packer templates for Linux

## Overview

This repository contains Packer templates for creating Linux virtual machines.


## Building the Vagrant boxes with Packer

To build all the boxes, you will need [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

We make use of JSON files containing user variables to build specific versions of Linux.

You tell `packer` to use a specific user variable file via the `-var-file=` command line option.

This will override the default options on the core `centos.json` packer template, which builds CentOS 7 by default.

For example, to build CentOS 7, use the following:

```sh
packer build -var-file=centos7.json centos.json
```

The boxcutter templates currently support the following desktop virtualization strings:

* `virtualbox-iso` - [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Exporting Virtual Machine to Azure

Generate your virtual machines to be compatible with Azure.

```sh
packer build -var-file=centos7.json -var 'azure=true' centos.json
```

You may also build the Desktop version which will install gnome + related tooling (vscode, xrdp, ...)

```sh
packer build -var-file=centos7-desktop.json -var 'azure=true' centos-desktop.json
```

Run the Azure to vhd conversion script.

```sh
./scripts/azure-vhd.sh _output/output-centos7-virtualbox-iso/centos7-disk001.vmdk

```

You will now need to follow the steps in the `docs/azure-vm.md` directory.

## OS Hardening

Right now the base O.S. has just a few security related configurations applied to it:

* Installs fail2ban to monitor bad SSH access
* Minor tweaks to SSH
* Set up automatic updates via yum cron

## Acknowledgements

Derived heavily from [Boxcutter][boxcutter] community driven cloud templates.

Additionally also consulted the [Packer guide to VM creation][microsoft] provided by Microsoft

<!-- Links Referenced -->

[boxcutter]:               https://github.com/boxcutter/centos
[devsec]:                  https://github.com/dev-sec/linux-baseline
[microsoft]:               https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer
[ssh]:                     https://github.com/dev-sec/ansible-ssh-hardening
