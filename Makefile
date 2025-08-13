SSH_USER ?= gamer
SSH_HOST ?= 192.168.0.100
DEPLOY_DIR := /tmp/deploy-$(SSH_HOST)

SUPPORTED_DEVICES := $(shell find ./test/devices -type f -printf '%f\n' | cut -d'.' -f1)
CACHE_NAME ?= shadowblip
PKGS := .\#gamepad-os-installer .\#gamescope

-include settings.mk

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: test
test: ## Build a test build of the flake OS configuration
	@rm -rf /tmp/test-flake
	@mkdir -p /tmp/test-flake
	@cp ./test/*.nix /tmp/test-flake
ifndef DEVICE
	@cp ./test/*.json /tmp/test-flake
else
	@echo "Building OS flake for device: $(DEVICE)"
	@cp ./test/devices/$(DEVICE).json /tmp/test-flake/facter.json
endif
	@sed -i 's|shadowblip.url = "path:.."|shadowblip.url = "$(PWD)"|g' /tmp/test-flake/flake.nix
	nixos-rebuild build --impure --flake /tmp/test-flake/#nixos

.PHONY: test-all
test-all: ## Build a test build of the flake OS configuration for all supported devices
	@for device in $(SUPPORTED_DEVICES); do \
		rm -f result; \
		$(MAKE) test DEVICE=$$device; \
	done

.PHONY: deploy
deploy: ## Build and deploy the flake to a remote host
	@rm -rf $(DEPLOY_DIR)
	@mkdir -p $(DEPLOY_DIR)
	@echo "Copying hardware configuration from $(SSH_HOST)..."
	scp $(SSH_USER)@$(SSH_HOST):/etc/nixos/*.nix $(DEPLOY_DIR)
	ssh -t $(SSH_USER)@$(SSH_HOST) sudo chmod +r /etc/nixos/facter.json || true
	scp $(SSH_USER)@$(SSH_HOST):/etc/nixos/*.json $(DEPLOY_DIR) || true
	cp ./test/flake.nix $(DEPLOY_DIR)
	sed -i 's|shadowblip.url = "path:.."|shadowblip.url = "$(PWD)"|g' $(DEPLOY_DIR)/flake.nix
	nixos-rebuild --target-host $(SSH_USER)@$(SSH_HOST) --ask-sudo-password --use-remote-sudo --impure --flake $(DEPLOY_DIR)/#nixos switch


.PHONY: update
update: ## Update flake inputs
	nix flake update


.PHONY: iso
iso: ## Build an ISO installer image
	nix \
		--extra-experimental-features nix-command \
		--extra-experimental-features flakes \
		build --impure .#nixosConfigurations.iso.config.system.build.isoImage


.PHONY: iso-publish
iso-publish: iso ## Build and publish the ISO installer image
	curl --location --header "PRIVATE-TOKEN: $(GITLAB_TOKEN)" \
		--output /tmp/iso-upload.txt \
		--request PUT \
		--progress-bar \
		--upload-file ./result/iso/*.iso \
		"https://gitlab.com/api/v4/projects/shadowapex%2Fos-flake/packages/generic/installer/1.0.0/installer.iso"


.PHONY: clean
clean:
	rm -rf result
	sudo nix-collect-garbage


.PHONY: cachix
cachix: ## Build flake and push to binary cache
	@echo "Pushing flake inputs to cache..."
	nix flake archive --json \
    | jq -r '.path,(.inputs|to_entries[].value.path)' \
    | cachix push $(CACHE_NAME)
	@echo "Pushing packages to cache..."
	nix build --no-link --print-out-paths $(PKGS) \
    | cachix push $(CACHE_NAME)
	@echo "Pushing OS build to cache..."
	@for device in $(SUPPORTED_DEVICES); do \
		rm -f result; \
		$(MAKE) test DEVICE=$$device cachix-push; \
	done


.PHONY: cachix-push
cachix-push:
	cachix push $(CACHE_NAME) ./result


.PHONY: in-docker
in-docker:
	docker run -it \
		--rm \
		-v "$(PWD):/src" \
		-w /root \
		nixos/nix:latest \
		bash -c 'cp -r /src ./ && chown -R root:root ./src && nix-shell -p gnumake --run "make -C src $(TARGET)"'
