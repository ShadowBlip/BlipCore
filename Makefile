SSH_USER ?= gamer
SSH_HOST ?= 192.168.0.100
DEPLOY_DIR := /tmp/deploy-$(SSH_HOST)

-include settings.mk

.PHONY: test
test:
	@rm -rf /tmp/test-flake
	@mkdir -p /tmp/test-flake
	cp ./test/*.nix /tmp/test-flake
	sed -i 's|shadowblip.url = "path:.."|shadowblip.url = "$(PWD)"|g' /tmp/test-flake/flake.nix
	nixos-rebuild build --impure --flake /tmp/test-flake/#nixos

.PHONY: deploy
deploy:
	@rm -rf $(DEPLOY_DIR)
	@mkdir -p $(DEPLOY_DIR)
	@echo "Copying hardware configuration from $(SSH_HOST)..."
	scp $(SSH_USER)@$(SSH_HOST):/etc/nixos/*.nix $(DEPLOY_DIR)
	cp ./test/flake.nix $(DEPLOY_DIR)
	sed -i 's|shadowblip.url = "path:.."|shadowblip.url = "$(PWD)"|g' $(DEPLOY_DIR)/flake.nix
	nixos-rebuild --target-host $(SSH_USER)@$(SSH_HOST) --use-remote-sudo --impure --flake $(DEPLOY_DIR)/#nixos switch

