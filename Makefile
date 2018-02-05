.PHONY: deps start stop clean image
.DEFAULT_GOAL := start

TEMPLATE_FILE := centos.json
AZURE_BIN := az
PACKER_BIN := packer
VAGRANT_BIN := vagrant
BOX := centos7-0.0.1

deps:
	@hash $(AZURE_BIN) > /dev/null 2>&1 || (echo "Install azure-cli to continue"; echo 1)
	@hash $(VAGRANT_BIN) > /dev/null 2>&1 || (echo "Install vagrant to continue"; echo 1)
	@hash $(PACKER_BIN) > /dev/null 2>&1 || (echo "Install packer to continue"; echo 1)

image: deps
    @$(PACKER_BIN) build -var-file=centos7.json -var 'azure=true' $(TEMPLATE_FILE)

start:
	@$(VAGRANT_BIN) up

stop:
	@$(VAGRANT_BIN) halt

clean:
	@$(VAGRANT_BIN) destroy -f
	@$(VAGRANT_BIN) box remove -f $(BOX)
