#!/usr/bin/env bash
# Préflight commun au poste de contrôle et à la CI. Ne modifie aucun service.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

echo "[1/5] shell"
find ansible/control-node ansible/roles/scheduled_tasks/files/scripts scripts \
  -type f -name '*.sh' -print0 | xargs -0 -r -n1 bash -n

echo "[2/5] Ansible"
(cd ansible && ansible-playbook --syntax-check playbooks/baseline.yml >/dev/null)
(cd ansible && ansible-playbook --syntax-check playbooks/scheduled-tasks.yml >/dev/null)
(cd ansible && ansible-playbook --syntax-check playbooks/sops-deliver-apps.yml >/dev/null)
(cd ansible && ansible-playbook --syntax-check playbooks/sops-deliver-authentik.yml >/dev/null)
(cd ansible && ansible-playbook --syntax-check playbooks/sops-deliver-traefik.yml >/dev/null)
(cd ansible && ansible-playbook --syntax-check playbooks/sops-deliver-vaultwarden.yml >/dev/null)

while IFS= read -r encrypted_file; do
  sops --decrypt "$encrypted_file" >/dev/null
done < <(find services -type f -name '*.enc.env' | sort)

echo "[3/5] OpenTofu"
tofu -chdir=iac/opentofu fmt -check -recursive
TOFU_CHECK_DIR=$(mktemp -d)
trap 'rm -rf -- "$TOFU_CHECK_DIR"' EXIT
cp iac/opentofu/*.tf iac/opentofu/.terraform.lock.hcl "$TOFU_CHECK_DIR/"
tofu -chdir="$TOFU_CHECK_DIR" init -backend=false -input=false >/dev/null
TF_VAR_state_passphrase=ci-validation tofu -chdir="$TOFU_CHECK_DIR" validate

echo "[4/5] Packer"
packer fmt -check -recursive iac/packer

echo "[5/5] Docker Compose"
while IFS= read -r file; do
  docker compose -f "$file" config --no-interpolate --quiet
done < <(find services -type f \( -name 'docker-compose.yml' -o -name 'compose.yaml' \) \
  ! -path '*/monitoring/netbox/*' | sort)
docker compose -f user-docs/docker-compose.yml config --quiet

echo "Préflight réussi."
