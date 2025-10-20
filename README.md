# Keycloak + Infinispan Multi‑site (Budapest, Vienna, London)

- Discovery: JGroups **GossipRouter + TUNNEL**, cross-site via **RELAY2**
- Public TLS: **HAProxy** on :443 with SAN cert for all `*.localhost` hostnames
- Origin TLS: HAProxy → Keycloak on :8443 (re-encryption). Infinispan consoles remain HTTP behind TLS edge.
- Sites can be started/stopped independently.

## Quickstart

```bash
make wan
make hosts-add
make pki-init
make trust-info   # follow instructions to trust the local root CA once

# bring up sites
make up-bud
make up-vie
make up-lon

# bring up edge
make up-edge
```

Open:
- Keycloak: https://login.bp.localhost , https://login.vin.localhost , https://login.london.localhost
- Infinispan consoles: https://admin.infini.bp.localhost/console , .../vin... , .../lon...

To stop:
```bash
make down-all
make hosts-remove
```
