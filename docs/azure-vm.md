### Prepare a Linux virtual machine for Azure

```sh
az group create -n packer -l "eastus"
```

```sh
az storage account create \
    --resource-group packer \
    --location eastus \
    --name vhdpacker \
    --kind Storage \
    --sku Standard_LRS
```

```sh
az storage account keys list \
    --resource-group packer \
    --account-name vhdpacker
```

```sh
az storage container create \
    --account-name vhdpacker \
    --name centos
```

```sh
az storage blob upload --account-name vhdpacker \
    --account-key key1 \
    --container-name centos \
    --type page \
    --file _output/output-centos7-virtualbox-iso/centos7-disk001.vmdk.vhd \
    --name centos7-0.0.1.vhd
```

## Managed Disk

```sh
az disk create \
    --resource-group packer \
    --name centosMD \
    --source https://vhdpacker.blob.core.windows.net/centos/centos7-0.0.1.vhd
```

```sh
az vm create \
    --resource-group packer \
    --location eastus \
    --name centosVM \
    --os-type linux \
    --size Standard_DS3_v2 \
    --attach-os-disk centosMD
```

## UnManaged Disk

```sh
az vm create \
    --resource-group packer \
    --location eastus \
    --name centosVM \
    --os-type linux \
    --storage-account vhdpacker \
    --admin-username vagrant \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --image https://vhdpacker.blob.core.windows.net/centos/centos7-0.0.1.vhd \
    --use-unmanaged-disk
```
