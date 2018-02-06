# Packer templates for Linux

## Overview

This repository contains Packer templates for creating Linux virtual machines.


## Building the Vagrant boxes with Packer

To build all the boxes, you will need [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

We make use of JSON files containing user variables to build specific versions of Linux.
You tell `packer` to use a specific user variable file via the `-var-file=` command line
option.  This will override the default options on the core `centos.json` packer template,
which builds CentOS 7 by default.

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

Run the Azure to vhd conversion script.

```sh
./scripts/azure-vhd.sh _output/output-centos7-virtualbox-iso/centos7-disk001.vmdk
```

You will now need to follow the steps in the `docs/azure-vm.md` directory.

## Acknowledgements

Derived heavily from [Boxcutter][boxcutter] community driven cloud templates.

Additionally also consulted the [Packer guide to VM creation][microsoft] provided by Microsoft

<!-- Links Referenced -->

[boxcutter]:               https://github.com/boxcutter/centos
[microsoft]:               https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer
