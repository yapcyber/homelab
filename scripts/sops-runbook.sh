#!/usr/bin/env bash
# Runbook exécutable SOPS/Age : diagnostic, test ou chiffrement d'un fichier.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "ERREUR: lancer ce script depuis le dépôt homelab." >&2; exit 1;
}
CONFIG="$ROOT/.sops.yaml"
KEYFILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

die() { echo "ERREUR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "commande absente: $1"; }
need sops
need age-keygen
[ -r "$CONFIG" ] || die ".sops.yaml absent"
[ -r "$KEYFILE" ] || die "clé Age privée absente: $KEYFILE"
[ "$(stat -c %a "$KEYFILE")" = 600 ] || die "la clé Age doit être en mode 600"

configured=$(sed -n 's/^[[:space:]]*age:[[:space:]]*>-[[:space:]]*$//; /age1/{s/[[:space:]]//g;p;q}' "$CONFIG")
[ -n "$configured" ] || die "destinataire Age introuvable dans .sops.yaml"
derived=$(age-keygen -y "$KEYFILE" 2>/dev/null)
[ "$configured" = "$derived" ] || die "la clé privée ne correspond pas à .sops.yaml"
export SOPS_AGE_KEY_FILE="$KEYFILE"

round_trip_test() {
  local work plain encrypted decrypted
  work=$(mktemp -d "$ROOT/.sops-test.XXXXXX")
  trap 'rm -rf -- "$work"' RETURN
  plain="$work/plain.env"
  encrypted="$work/test.enc.env"
  decrypted="$work/decrypted.env"
  printf 'SOPS_TEST=round-trip-ok\n' > "$plain"
  chmod 600 "$plain"
  (cd "$ROOT" && sops --encrypt --filename-override test.enc.env "$plain" > "$encrypted")
  sops --decrypt "$encrypted" > "$decrypted"
  cmp -s "$plain" "$decrypted" || die "échec de l'aller-retour SOPS"
  rm -rf -- "$work"
  trap - RETURN
  echo "OK: SOPS $(sops --version | head -1), clé Age et aller-retour validés."
}

encrypt_file() {
  local input=$1 output=$2
  [ -f "$input" ] || die "fichier source absent: $input"
  [[ "$output" = *.enc.env ]] || die "la destination doit finir par .enc.env"
  [ ! -e "$output" ] || die "destination déjà existante: $output"
  git -C "$ROOT" ls-files --error-unmatch "$input" >/dev/null 2>&1 \
    && die "le fichier source est suivi par Git; retirez-le de l'index d'abord"
  umask 077
  (cd "$ROOT" && sops --encrypt --filename-override "${output##*/}" "$input" > "$output")
  sops --decrypt "$output" | cmp -s - "$input" || {
    rm -f -- "$output"; die "validation du fichier chiffré échouée";
  }
  echo "OK: $output créé et déchiffrement vérifié."
  echo "Le fichier source n'a pas été supprimé: $input"
}

case "${1:-test}" in
  test) round_trip_test ;;
  encrypt)
    [ "$#" -eq 3 ] || die "usage: $0 encrypt SOURCE.env DESTINATION.enc.env"
    round_trip_test
    encrypt_file "$2" "$3"
    ;;
  *) die "usage: $0 [test | encrypt SOURCE.env DESTINATION.enc.env]" ;;
esac
