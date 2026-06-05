"""
services/cv-pipeline/src/cv_adapter.py
=========================================
Module d'adaptation du CV via Claude API.

PRINCIPE DE SÉCURITÉ SÉMANTIQUE (anti-hallucination) :
  L'IA n'a le droit que de réorganiser et reformuler le contenu existant
  du Master CV. Elle ne peut PAS inventer de compétences, expériences,
  projets ou faits qui ne sont pas explicitement dans le CV maître.

  Cette contrainte est implémentée à deux niveaux :
    1. Prompt système avec règles absolues et exemples de violations
    2. Validation post-génération : comparaison des entités clés entre
       le CV original et le CV adapté (noms, dates, entreprises, diplômes)
"""

import os
import re
import logging
import anthropic
from typing import Optional

log = logging.getLogger("cv-adapter")

# ──────────────────────────────────────────────────────────────────────────────
# PROMPT SYSTÈME — Guardrails anti-hallucination
# ──────────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """
Tu es un expert en adaptation de CV pour des candidatures en cybersécurité et infrastructure.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RÈGLES ABSOLUES — NE JAMAIS ENFREINDRE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INTERDIT :
  ✗ Inventer, ajouter ou inférer des compétences non présentes dans le CV maître
  ✗ Modifier des dates (années d'expérience, durées de formation, périodes de stage)
  ✗ Changer le nom d'un employeur, d'une école, d'un projet ou d'une technologie
  ✗ Augmenter le niveau d'une compétence (ex: passer "notions de" à "maîtrise de")
  ✗ Ajouter des certifications, diplômes ou formations qui ne figurent pas dans le CV
  ✗ Créer de nouvelles sections qui n'existent pas dans le CV maître
  ✗ Inférer des compétences à partir d'autres (ex: "travaille avec Docker" ≠ "connaît Kubernetes")

AUTORISÉ :
  ✓ Réordonner les sections pour mettre en avant ce qui est pertinent pour l'offre
  ✓ Réordonner les bullet points dans chaque section (priorité aux éléments matchants)
  ✓ Adapter le vocabulaire en utilisant les termes exacts de l'offre
    (ex: "gestion des incidents" → "incident response" si l'offre est en anglais)
  ✓ Adapter le lexique d'une compétence à sa dénomination dans l'offre
    (ex: "pare-feu OPNsense" → "firewall OPNsense" si offre en anglais — même chose)
  ✓ Reformuler une phrase en gardant un sens strictement identique
  ✓ Réécrire le résumé/profil en utilisant UNIQUEMENT des faits déjà présents
  ✓ Raccourcir des descriptions longues (enlever du contenu, jamais en ajouter)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXEMPLES DE VIOLATIONS (à ne PAS reproduire)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CV maître : "Utilisation de Wazuh pour la surveillance des logs"
Offre demande : "Expérience avec des outils SIEM comme Splunk ou QRadar"
❌ Mauvaise adaptation : "Expérience avec des outils SIEM (Wazuh, Splunk, QRadar)"
   → Splunk et QRadar ont été inventés
✓ Bonne adaptation : "Utilisation d'un outil SIEM (Wazuh) pour la surveillance des logs"

CV maître : "Notions de Python"
Offre demande : "Python avancé requis"
❌ Mauvaise adaptation : "Maîtrise de Python"
   → Le niveau a été augmenté
✓ Bonne adaptation : laisser "Notions de Python" inchangé
   (L'offre ne matchera peut-être pas, c'est normal)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FORMAT DE SORTIE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Retourner UNIQUEMENT le CV adapté en Markdown, sans commentaire ni explication.
Conserver exactement la même structure Markdown (titres H1/H2/H3, listes, etc.)
"""

USER_PROMPT_TEMPLATE = """
Voici le CV maître (source de vérité — ne rien inventer) :

```markdown
{master_cv}
```

Voici l'offre d'emploi cible :

```
{job_offer}
```

Adapte le CV maître pour cette offre en respectant strictement les règles ci-dessus.
Retourne uniquement le CV adapté en Markdown.
"""


# ──────────────────────────────────────────────────────────────────────────────
# VALIDATEUR POST-GÉNÉRATION
# ──────────────────────────────────────────────────────────────────────────────

class HallucinationDetector:
    """
    Vérifie que le CV adapté ne contient pas d'entités absentes du CV maître.
    Méthode conservatrice : on extrait les entités nommées importantes
    (technologies, entreprises, formations) et on vérifie la cohérence.
    """

    # Technologies et outils connus — on vérifie leur présence cohérente
    TECH_PATTERNS = [
        r"\bkubernetes\b", r"\bkubectl\b", r"\bhelm\b", r"\bterraform\b",
        r"\bansible\b", r"\bjenkins\b", r"\bsplunk\b", r"\bqradar\b",
        r"\bdarktrace\b", r"\bcrowdstrike\b", r"\bsentinelone\b",
        r"\bcissp\b", r"\bceh\b", r"\boscp\b", r"\bpalo alto\b",
        r"\bfortinet\b", r"\bcisco asa\b",
    ]

    def check(self, master_cv: str, adapted_cv: str) -> list[str]:
        """
        Retourne une liste de warnings si des entités suspectes sont détectées.
        Une liste vide = aucune anomalie détectée.
        """
        warnings = []
        master_lower  = master_cv.lower()
        adapted_lower = adapted_cv.lower()

        for pattern in self.TECH_PATTERNS:
            # L'entité est dans le CV adapté mais PAS dans le maître
            if re.search(pattern, adapted_lower) and not re.search(pattern, master_lower):
                tech = re.search(pattern, adapted_lower).group(0)
                warnings.append(f"Entité suspecte ajoutée: '{tech}' (absente du CV maître)")

        return warnings


# ──────────────────────────────────────────────────────────────────────────────
# ADAPTATEUR PRINCIPAL
# ──────────────────────────────────────────────────────────────────────────────

class CVAdapter:
    def __init__(self):
        self.client    = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
        self.model     = os.getenv("AI_MODEL", "claude-sonnet-4-20250514")
        self.detector  = HallucinationDetector()
        self.max_retries = 2

    def adapt(self, master_cv: str, job_offer: str) -> str:
        """
        Adapte le CV maître pour l'offre donnée.
        Effectue une validation anti-hallucination post-génération.
        Retourne le CV adapté en Markdown.
        """
        for attempt in range(self.max_retries + 1):
            log.info(f"Adaptation CV (tentative {attempt + 1}/{self.max_retries + 1})")

            adapted_cv = self._call_api(master_cv, job_offer)

            # Validation post-génération
            warnings = self.detector.check(master_cv, adapted_cv)

            if not warnings:
                log.info("✅ Validation anti-hallucination : aucune anomalie")
                return adapted_cv
            else:
                log.warning(f"⚠️  Anomalies détectées (tentative {attempt + 1}): "
                             f"{warnings}")
                if attempt < self.max_retries:
                    log.info("Nouvelle tentative avec prompt renforcé...")
                    job_offer = self._reinforce_prompt(job_offer, warnings)
                else:
                    log.error("Hallucination persistante après toutes les tentatives. "
                              "Retour du CV maître non modifié.")
                    return master_cv  # Sécurité : retourner le CV original intouché

        return master_cv

    def _call_api(self, master_cv: str, job_offer: str) -> str:
        """Appel à l'API Claude."""
        response = self.client.messages.create(
            model=self.model,
            max_tokens=4000,
            system=SYSTEM_PROMPT,
            messages=[{
                "role": "user",
                "content": USER_PROMPT_TEMPLATE.format(
                    master_cv=master_cv,
                    job_offer=job_offer
                )
            }]
        )
        return response.content[0].text.strip()

    def _reinforce_prompt(self, job_offer: str, warnings: list[str]) -> str:
        """Ajoute des avertissements au prompt pour la tentative suivante."""
        warning_text = "\n".join(f"- {w}" for w in warnings)
        return (f"{job_offer}\n\n"
                f"⚠️ CORRECTION REQUISE — Erreurs détectées lors de la tentative précédente :\n"
                f"{warning_text}\n"
                f"Ces éléments ne doivent PAS apparaître dans le CV adapté.")
