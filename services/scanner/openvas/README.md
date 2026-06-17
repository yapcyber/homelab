# Greenbone Community Edition (OpenVAS) — VM scanner (10.0.30.15)

Compose **fourni par l'editeur** (registry.community.greenbone.net).

NON epingle volontairement : le stack embarque des images de flux de
vulnerabilites (vulnerability-tests, scap-data, cert-bund...) qui doivent
rester a jour. Les figer reviendrait a geler les CVE detectees.

- Tags flottants `:stable` / `:latest` assumes.
- Hors perimetre Renovate (a mettre dans ignorePaths en 4b).
- MaJ = re-pull du compose Greenbone + `docker compose pull && up -d` sur la VM.
