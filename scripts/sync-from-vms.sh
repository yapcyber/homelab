#!/usr/bin/env bash
# Re-centralise les configs des VMs vers le hub. SENS : VM -> hub (lecture seule).
# Ne commit PAS : revue manuelle obligatoire.
set -euo pipefail
HUB="$HOME/homelab"
EXC=/tmp/rsync-exc
cat > "$EXC" <<'X'
.git
.env
*.env
.env.*
*.pem
*.key
certs/
data/
*-data/
*_data/
pgdata/
volumes/
*.db
*.sqlite
*.log
X
sync(){ echo ">> $1:$2 -> $3"; rsync -a --exclude-from="$EXC" ${4:-} "debian@$1:$2" "$HUB/$3"; }

sync 10.0.30.11 '~/netbox-docker/'                 services/monitoring/netbox/
sync 10.0.30.13 '~/jellystat/'                     services/media/jellystat/
sync 10.0.30.16 '~/firefly/'                       services/firefly/
sync 10.0.30.17 '~/osint/'                         services/osint/           "--exclude=spiderfoot/"
sync 10.0.30.15 '~/greenbone-community-container/' services/scanner/openvas/
# Traefik dynamic : on EXCLUT middlewares.yml (clé CrowdSec en dur côté infra)
sync 10.0.30.10 '~/homelab/services/infra/traefik/dynamic/' services/infra/traefik/dynamic/ "--exclude=middlewares.yml"

echo ">> wazuh (règles de détection seulement, pas de secrets)"
ssh debian@10.0.30.14 'mkdir -p ~/wazuh-export && \
  sudo docker exec single-node-wazuh.manager-1 cat /var/ossec/etc/rules/local_rules.xml > ~/wazuh-export/local_rules.xml && \
  sudo docker exec single-node-wazuh.manager-1 cat /var/ossec/etc/shared/linux-vms/agent.conf > ~/wazuh-export/agent.conf' \
  && rsync -a "debian@10.0.30.14:~/wazuh-export/" "$HUB/services/security/wazuh/" || echo "   (wazuh ignoré)"

cd "$HUB"; git add -A
echo "=================== SCAN ANTI-SECRET ==================="
if git diff --cached | grep -inE 'api[_-]?key|passwo?rd|secret|token|PRIVATE KEY|INDEXER_PASSWORD|ENABLE_BANKING' \
   | grep -vE '\$\{|os\.environ|CHANGEME|REPLACE|\.example|=$'; then
  echo ">>> ⚠️  Vérifie ces lignes AVANT de commit."
else
  echo ">>> OK : aucun secret littéral détecté."
fi
echo "Puis : git diff --cached --stat  →  git commit -m '...'  →  git push origin main"
