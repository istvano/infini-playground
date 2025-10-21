SHELL := /bin/bash

env ?= .env
include $(env)
export $(shell sed 's/=.*//' $(env))

EDGE_PEM := $(PKI_DIR)/edge.pem
ROOT_CRT := $(PKI_DIR)/root_ca.crt
ROOT_KEY := $(PKI_DIR)/root_ca.key
LEAF_CRT := $(PKI_DIR)/edge.crt
LEAF_KEY := $(PKI_DIR)/edge.key

HOSTS_CLIENT := 127.0.0.1 client.bp.localhost client.vie.localhost client.lon.localhost
HOSTS_LOGIN := 127.0.0.1 login.bp.localhost login.vie.localhost login.lon.localhost
HOSTS_CACHE := 127.0.0.1 admin.infini.bp.localhost admin.infini.vie.localhost admin.infini.lon.localhost

DIAG_NET ?= container:edge-haproxy
DIAG_CMD ?= 
DIAG_IMG ?= ghcr.io/nicolaka/netshoot

VOLUMES := budapest_bud_pgdata vienna_vie_pgdata london_lon_pgdata

include help.mk

$(eval $(call defw,IP_ADDRESS,$(IP_ADDRESS)))
$(eval $(call defw,ENV,$(env)))
$(eval $(call defw,DOCKER,docker))
$(eval $(call defw,CURL,curl))
$(eval $(call defw,COMPOSE,docker-compose))
$(eval $(call defw,UNAME,$(UNAME_S)-$(UNAME_P)))

$(PKI_DIR):
	mkdir -p $(PKI_DIR)

.PHONY: infra/net-create
infra/net-create: ##@infra Create docker network
	./scripts/create-wan-network.sh

.PHONY: infra/pki-init
infra/pki-init: $(PKI_DIR) ##@infra Initialize PKI (root CA + SAN leaf cert)
	@echo ">> Generating offline Root CA..."
	docker run --rm -v $$PWD/$(PKI_DIR):/pki smallstep/step-cli:latest \
		step certificate create "Local Dev Root CA" /pki/root_ca.crt /pki/root_ca.key \
		--profile root-ca --no-password --insecure
	@echo ">> Generating SAN leaf cert for all public hostnames..."
	docker run --rm -v $$PWD/$(PKI_DIR):/pki smallstep/step-cli:latest \
		step certificate create "Edge Public Cert" /pki/edge.crt /pki/edge.key \
		--profile leaf --no-password --insecure \
		--ca /pki/root_ca.crt --ca-key /pki/root_ca.key \
		--san client.bp.localhost \
		--san client.vie.localhost \
		--san client.lon.localhost \
		--san login.bp.localhost \
		--san login.vie.localhost \
		--san login.lon.localhost \
		--san admin.infini.bp.localhost \
		--san admin.infini.vie.localhost \
		--san admin.infini.lon.localhost
	@echo ">> Building HAProxy PEM (cert+key)..."
	cat $(LEAF_CRT) $(LEAF_KEY) > $(EDGE_PEM)
	@echo "Done. Certs in $(PKI_DIR). Run 'make trust-info' to see how to trust the root locally."

.PHONY: infra/trust-info
infra/trust-info: ##@infra Show how to trust the root CA locally
	@echo
	@echo "Trust the root CA locally (manual, once):"
	@echo "  - macOS:    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(ROOT_CRT)"
	@echo "  - Ubuntu:   sudo cp $(ROOT_CRT) /usr/local/share/ca-certificates/kispn-root-ca.crt && sudo update-ca-certificates"
	@echo "  - Firefox:  Preferences -> Certificates -> View -> Authorities -> Import $(ROOT_CRT)"
	@echo "Browsers must trust the root to avoid warnings."
	@echo

.PHONY: infra/hosts-add
infra/hosts-add: ##@infra Add /etc/hosts entries
	@echo "Adding /etc/hosts entries (requires sudo)..."
	@if ! grep -q "# kispn-demo" /etc/hosts 2>/dev/null; then \
		echo "" | sudo tee -a /etc/hosts > /dev/null; \
		echo "# kispn-demo start" | sudo tee -a /etc/hosts > /dev/null; \
		echo "127.0.0.1 $(wordlist 2,999,$(HOSTS_CLIENT))" | sudo tee -a /etc/hosts > /dev/null; \
		echo "127.0.0.1 $(wordlist 2,999,$(HOSTS_LOGIN))" | sudo tee -a /etc/hosts > /dev/null; \
		echo "127.0.0.1 $(wordlist 2,999,$(HOSTS_CACHE))" | sudo tee -a /etc/hosts > /dev/null; \
		echo "# kispn-demo end" | sudo tee -a /etc/hosts > /dev/null; \
		echo "Done."; \
	else \
		echo "Entries already exist, skipping."; \
	fi

.PHONY: infra/hosts-remove
infra/hosts-remove: ##@infra Remove /etc/hosts entries
	@echo "Removing /etc/hosts entries (requires sudo)..."
	@sudo sed -i.bak '/# kispn-demo start/,/# kispn-demo end/d' /etc/hosts
	@echo "Done. Backup: /etc/hosts.bak"

.PHONY: infra/volumes/delete
infra/volumes/delete: ##@infra Remove all site volumes
	@echo "Removing Docker volumes..."
	@for vol in $(VOLUMES); do \
		if docker volume ls -q | grep -q "^$$vol$$"; then \
			docker volume rm $$vol && echo "Removed $$vol"; \
		else \
			echo "Volume $$vol not found, skipping"; \
		fi \
	done
	@echo "Done."

.PHONY: infra/net-diag
infra/net-diag: ##@infra Diagnose network issues
	docker run --rm -it --network $(DIAG_NET) --cap-add NET_ADMIN --cap-add NET_RAW $(DIAG_IMG) $(DIAG_CMD)

# SITES

.PHONY: all/up
all/up: sites/bud/up sites/vie/up sites/lon/up edge/up ##@all Start all sites and edge

.PHONY: all/down
all/down: client/down edge/down sites/bud/down sites/vie/down sites/lon/down ##@all Stop all sites and edge and client

.PHONY: sites/bud/up
sites/bud/up: ##@sites Start Budapest site
	@cd sites/budapest && docker compose up -d

.PHONY: sites/vie/up
sites/vie/up: ##@sites Start Vienna site
	@cd sites/vienna && docker compose up -d

.PHONY: sites/lon/up
sites/lon/up: ##@sites Start London site
	@cd sites/london && docker compose up -d

.PHONY: sites/bud/down
sites/bud/down: ##@sites Stop Budapest site
	@cd sites/budapest && docker compose down -v

.PHONY: sites/vie/down
sites/vie/down: ##@sites Stop Vienna site
	@cd sites/vienna && docker compose down -v

.PHONY: sites/lon/down
sites/lon/down: ##@sites Stop London site
	@cd sites/london && docker compose down -v

.PHONY: sites/bud/logs
sites/bud/logs: ##@sites Follow Budapest site logs
	@cd sites/budapest && docker compose logs -f

.PHONY: sites/vie/logs
sites/vie/logs: ##@sites Follow Vienna site logs
	@cd sites/vienna && docker compose logs -f

.PHONY: sites/lon/logs
sites/lon/logs: ##@sites Follow London site logs
	@cd sites/london && docker compose logs -f


# EDGE Proxy

.PHONY: edge/up
edge/up: ##@edge Start edge services
	@cd edge && docker compose up -d

.PHONY: edge/down
edge/down: ##@edge Stop edge services
	@cd edge && docker compose down -v

.PHONY: edge/logs
edge/logs: ##@edge Follow edge logs
	@cd edge && docker compose logs -f

# Client
.PHONY: client/up
client/up: ##@client Start client services
	@cd client && docker compose up -d

.PHONY: client/down
client/down: ##@client Stop client services
	@cd client && docker compose down -v

.PHONY: client/logs
client/logs: ##@client Follow client logs
	@cd client && docker compose logs -f


