#!/usr/bin/env bash
# Revue quotidienne des agents Wazuh (cron-securite #12).
# Alerte si un agent est Disconnected / Never connected (angle mort SIEM).
set -u
out=$(docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_control -l 2>&1) || {
  /usr/local/bin/homelab-alert "🛡️ $(hostname) : agent_control injoignable" "$(echo "$out" | tail -c 300)" high
  exit 1
}
bad=$(echo "$out" | grep -E "Disconnected|Never connected" || true)
if [ -n "$bad" ]; then
  /usr/local/bin/homelab-alert "🛡️ Wazuh : agent(s) déconnecté(s)" "$bad" high
  exit 1
fi
