SHELL := /bin/bash
PKI_DIR := pki
EDGE_PEM := $(PKI_DIR)/edge.pem
ROOT_CRT := $(PKI_DIR)/root_ca.crt
ROOT_KEY := $(PKI_DIR)/root_ca.key
LEAF_CRT := $(PKI_DIR)/edge.crt
LEAF_KEY := $(PKI_DIR)/edge.key

HOSTS_LOGIN := 127.0.0.1 login.bp.localhost login.vin.localhost login.london.localhost # kispn-demo
HOSTS_CACHE := 127.0.0.1 admin.infini.bp.localhost admin.infini.vin.localhost admin.infini.lon.localhost # kispn-demo

.PHONY: help wan hosts-add hosts-remove pki-init trust-info up-bud up-vie up-lon up-edge up-all down-bud down-vie down-lon down-edge down-all logs

help:
	@echo "Targets:"
	@echo "  pki-init        - generate offline root CA and SAN leaf cert with step-cli"
	@echo "  trust-info      - print how to trust the root CA locally"
	@echo "  wan             - create shared external 'wan' network"
	@echo "  hosts-add|hosts-remove - manage /etc/hosts for local domains"
	@echo "  up-<site>|down-<site> - start/stop site-budapest|vienna|london"
	@echo "  up-edge|down-edge - start/stop HAProxy TLS edge"
	@echo "  up-all|down-all - everything"
	@echo "  logs            - tail edge logs"

$(PKI_DIR):
	mkdir -p $(PKI_DIR)

pki-init: $(PKI_DIR)
	@echo ">> Generating offline Root CA..."
	docker run --rm -v $$PWD/$(PKI_DIR):/pki smallstep/step-cli:latest \
		step certificate create "Local Dev Root CA" /pki/root_ca.crt /pki/root_ca.key \
		--profile root-ca --no-password --insecure
	@echo ">> Generating SAN leaf cert for all public hostnames..."
	docker run --rm -v $$PWD/$(PKI_DIR):/pki smallstep/step-cli:latest \
		step certificate create "Edge Public Cert" /pki/edge.crt /pki/edge.key \
		--profile leaf --no-password --insecure \
		--ca /pki/root_ca.crt --ca-key /pki/root_ca.key \
		--san login.bp.localhost \
		--san login.vin.localhost \
		--san login.london.localhost \
		--san admin.infini.bp.localhost \
		--san admin.infini.vin.localhost \
		--san admin.infini.lon.localhost
	@echo ">> Building HAProxy PEM (cert+key)..."
	cat $(LEAF_CRT) $(LEAF_KEY) > $(EDGE_PEM)
	@echo "Done. Certs in $(PKI_DIR). Run 'make trust-info' to see how to trust the root locally."

trust-info:
	@echo
	@echo "Trust the root CA locally (manual, once):"
	@echo "  - macOS:    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(ROOT_CRT)"
	@echo "  - Ubuntu:   sudo cp $(ROOT_CRT) /usr/local/share/ca-certificates/kispn-root-ca.crt && sudo update-ca-certificates"
	@echo "  - Firefox:  Preferences -> Certificates -> View -> Authorities -> Import $(ROOT_CRT)"
	@echo "Browsers must trust the root to avoid warnings."
	@echo

wan:
	./scripts/create-wan-network.sh

hosts-add:
	@echo "Adding /etc/hosts entries (requires sudo)..."
	@sudo bash -c 'grep -q "# kispn-demo" /etc/hosts || { \
	  echo "$(HOSTS_LOGIN)" >> /etc/hosts; \
	  echo "$(HOSTS_CACHE)" >> /etc/hosts; \
	}'; \
	echo "Done."

hosts-remove:
	@echo "Removing /etc/hosts entries (requires sudo)..."
	@sudo sed -i.bak '/# kispn-demo/d' /etc/hosts
	@echo "Done. Backup: /etc/hosts.bak"

up-bud: wan
	@cd site-budapest && docker compose up -d

up-vie: wan
	@cd site-vienna && docker compose up -d

up-lon: wan
	@cd site-london && docker compose up -d

up-edge: wan pki-init
	@cd edge && docker compose up -d

up-all: wan pki-init up-bud up-vie up-lon up-edge

down-bud:
	@cd site-budapest && docker compose down -v

down-vie:
	@cd site-vienna && docker compose down -v

down-lon:
	@cd site-london && docker compose down -v

down-edge:
	@cd edge && docker compose down -v

down-all: down-edge down-bud down-vie down-lon

logs:
	@cd edge && docker compose logs -f
