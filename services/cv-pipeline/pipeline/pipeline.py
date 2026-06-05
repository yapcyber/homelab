"""
services/cv-pipeline/src/pipeline.py
======================================
Orchestrateur du pipeline de candidature automatisé.

Workflow :
  1. Monitor la boîte IMAP pour les nouvelles alertes d'offres
  2. Extraire et parser le contenu des offres
  3. Filtrer selon les critères (domaine, niveau, géographie)
  4. Si valide : créer une branche Git + adapter le CV via IA
  5. Notifier par email avec le PDF compilé
"""

import imaplib
import email
import sqlite3
import time
import re
import logging
import os
import subprocess
import smtplib
import yaml
import requests
from pathlib import Path
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dataclasses import dataclass, field
from typing import Optional
from cv_adapter import CVAdapter

# ──────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("cv-pipeline")


# ──────────────────────────────────────────────────────────────────────────────
# MODÈLE DE DONNÉES
# ──────────────────────────────────────────────────────────────────────────────

@dataclass
class JobOffer:
    """Représente une offre d'emploi extraite d'un email."""
    id: Optional[int] = None
    title: str = ""
    company: str = ""
    location: str = ""
    description: str = ""
    url: str = ""
    source: str = ""          # linkedin / hellowk / wttj / other
    received_at: str = ""
    # Résultat du filtrage
    status: str = "pending"   # pending / accepted / rejected
    reject_reason: str = ""
    commute_minutes: Optional[int] = None
    # Résultat de l'adaptation
    git_branch: str = ""
    cv_generated_at: str = ""


# ──────────────────────────────────────────────────────────────────────────────
# BASE DE DONNÉES
# ──────────────────────────────────────────────────────────────────────────────

class Database:
    def __init__(self, path: str = "/data/cv-pipeline.db"):
        self.conn = sqlite3.connect(path, check_same_thread=False)
        self._init_schema()

    def _init_schema(self):
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS jobs (
                id              INTEGER PRIMARY KEY AUTOINCREMENT,
                title           TEXT NOT NULL,
                company         TEXT NOT NULL,
                location        TEXT,
                description     TEXT,
                url             TEXT UNIQUE,
                source          TEXT,
                received_at     TEXT,
                status          TEXT DEFAULT 'pending',
                reject_reason   TEXT,
                commute_minutes INTEGER,
                git_branch      TEXT,
                cv_generated_at TEXT,
                created_at      TEXT DEFAULT (datetime('now'))
            )
        """)
        self.conn.commit()

    def upsert_job(self, job: JobOffer) -> int:
        """Insère ou met à jour une offre. Retourne l'ID."""
        cur = self.conn.execute("""
            INSERT INTO jobs (title, company, location, description, url,
                              source, received_at, status, reject_reason,
                              commute_minutes, git_branch, cv_generated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(url) DO UPDATE SET
              status = excluded.status,
              reject_reason = excluded.reject_reason,
              commute_minutes = excluded.commute_minutes,
              git_branch = excluded.git_branch,
              cv_generated_at = excluded.cv_generated_at
        """, (job.title, job.company, job.location, job.description,
              job.url, job.source, job.received_at, job.status,
              job.reject_reason, job.commute_minutes, job.git_branch,
              job.cv_generated_at))
        self.conn.commit()
        return cur.lastrowid

    def is_known(self, url: str) -> bool:
        cur = self.conn.execute("SELECT 1 FROM jobs WHERE url=?", (url,))
        return cur.fetchone() is not None


# ──────────────────────────────────────────────────────────────────────────────
# LECTEUR IMAP
# ──────────────────────────────────────────────────────────────────────────────

class IMAPReader:
    def __init__(self):
        self.host = os.environ["IMAP_HOST"]
        self.port = int(os.getenv("IMAP_PORT", 993))
        self.user = os.environ["IMAP_USER"]
        self.password = os.environ["IMAP_PASS"]
        self.folder = os.getenv("IMAP_FOLDER", "INBOX")

    def fetch_unread(self) -> list[email.message.Message]:
        """Récupère tous les emails non lus et les marque comme lus."""
        messages = []
        try:
            conn = imaplib.IMAP4_SSL(self.host, self.port)
            conn.login(self.user, self.password)
            conn.select(self.folder)
            _, uids = conn.search(None, "UNSEEN")
            for uid in uids[0].split():
                _, data = conn.fetch(uid, "(RFC822)")
                msg = email.message_from_bytes(data[0][1])
                messages.append(msg)
                conn.store(uid, "+FLAGS", "\\Seen")
            conn.logout()
            log.info(f"IMAP: {len(messages)} nouveaux emails récupérés")
        except Exception as e:
            log.error(f"IMAP error: {e}")
        return messages


# ──────────────────────────────────────────────────────────────────────────────
# PARSEUR D'OFFRES
# ──────────────────────────────────────────────────────────────────────────────

class OfferParser:
    """Extrait les informations d'une offre depuis le corps d'un email."""

    SOURCE_PATTERNS = {
        "linkedin":  [r"linkedin\.com", r"LinkedIn Job Alert"],
        "hellowk":   [r"hellowork\.com", r"Hellowork"],
        "wttj":      [r"welcometothejungle\.com", r"Welcome to the Jungle"],
    }

    def parse(self, msg: email.message.Message) -> Optional[JobOffer]:
        subject = msg.get("Subject", "")
        sender  = msg.get("From", "")
        body    = self._get_body(msg)

        source = self._detect_source(sender + subject + body)
        job = self._extract_fields(subject, body, source)

        if not job.title or not job.company:
            log.debug(f"Email ignoré (pas une offre d'emploi): {subject}")
            return None

        return job

    def _get_body(self, msg) -> str:
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() in ("text/plain", "text/html"):
                    try:
                        return part.get_payload(decode=True).decode("utf-8", errors="ignore")
                    except Exception:
                        pass
        return msg.get_payload(decode=True).decode("utf-8", errors="ignore")

    def _detect_source(self, text: str) -> str:
        for source, patterns in self.SOURCE_PATTERNS.items():
            if any(re.search(p, text, re.IGNORECASE) for p in patterns):
                return source
        return "other"

    def _extract_fields(self, subject: str, body: str, source: str) -> JobOffer:
        job = JobOffer(source=source, received_at=datetime.now().isoformat())

        # Extraire le titre depuis le sujet (heuristiques par source)
        title_match = re.search(r"(?:Offre|Job|Poste)\s*:\s*(.+?)(?:\s*-|\s*chez|\n|$)",
                                subject, re.IGNORECASE)
        job.title = title_match.group(1).strip() if title_match else subject[:80]

        # Extraire l'entreprise
        company_match = re.search(r"chez\s+([A-Z][^\n\-\.]{2,40})", body + subject,
                                  re.IGNORECASE)
        job.company = company_match.group(1).strip() if company_match else "Inconnu"

        # Extraire la localisation
        location_match = re.search(
            r"(?:Lieu|Location|Localisation|Ville)\s*:?\s*([^\n\|,]{3,50})",
            body, re.IGNORECASE
        )
        job.location = location_match.group(1).strip() if location_match else ""

        # Extraire l'URL de l'offre
        url_match = re.search(
            r"https?://(?:www\.)?(?:linkedin|hellowork|welcometothejungle)\.[a-z]+/[^\s\"<>]{10,200}",
            body
        )
        job.url = url_match.group(0) if url_match else ""

        # Garder le corps comme description (sera analysé par le filtre)
        # Nettoyer le HTML basique
        job.description = re.sub(r"<[^>]+>", " ", body)
        job.description = re.sub(r"\s{2,}", " ", job.description).strip()[:5000]

        return job


# ──────────────────────────────────────────────────────────────────────────────
# FILTRE D'OFFRES
# ──────────────────────────────────────────────────────────────────────────────

class OfferFilter:
    """Applique les 3 critères de filtrage : domaine, niveau, géographie."""

    def __init__(self, criteria_path: str = "/config/criteria.yml"):
        with open(criteria_path) as f:
            self.criteria = yaml.safe_load(f)
        self.ors_key = os.environ["ORS_API_KEY"]
        self.home    = os.environ["HOME_ADDRESS"]
        self.max_min = int(os.getenv("MAX_COMMUTE_MINUTES", 60))

    def evaluate(self, job: JobOffer) -> tuple[bool, str]:
        """
        Retourne (True, "") si l'offre est acceptée,
        ou (False, "raison du rejet") sinon.
        """
        text = f"{job.title} {job.description}".lower()

        # ── Critère 1 : Domaine ────────────────────────────────────────────
        domain_cfg = self.criteria["domain"]
        keywords = [k.lower() for k in domain_cfg["keywords"]]
        excludes = [k.lower() for k in domain_cfg.get("exclude_keywords", [])]

        if not any(k in text for k in keywords):
            return False, "hors_domaine"
        if any(k in text for k in excludes):
            return False, "exclu_domaine"

        # ── Critère 2 : Niveau ─────────────────────────────────────────────
        level_cfg = self.criteria["level"]
        contracts = [c.lower() for c in level_cfg["contract_types"]]
        if level_cfg.get("contract_types_require_any"):
            if not any(c in text for c in contracts):
                return False, "type_contrat_incompatible"

        exp_excl = [k.lower() for k in level_cfg.get("experience_exclude_keywords", [])]
        if any(k in text for k in exp_excl):
            return False, "trop_senior"

        # ── Critère 3 : Géographie ─────────────────────────────────────────
        geo_cfg = self.criteria["geography"]

        # Vérifier les lieux toujours acceptés (télétravail, Lille, etc.)
        always_ok = [loc.lower() for loc in geo_cfg.get("always_accept_locations", [])]
        if any(loc in job.location.lower() or loc in text for loc in always_ok):
            return True, ""

        # Vérifier les lieux toujours refusés
        always_ko = [loc.lower() for loc in geo_cfg.get("always_reject_locations", [])]
        if any(loc in job.location.lower() for loc in always_ko):
            return False, f"trop_loin:{job.location}"

        # Calculer le temps de trajet si une localisation est disponible
        if job.location:
            minutes = self._get_commute(job.location)
            job.commute_minutes = minutes
            if minutes and minutes > self.max_min:
                return False, f"trajet_{minutes}min>_{self.max_min}min"
        else:
            log.warning(f"Pas de localisation pour '{job.title}' — offre acceptée par défaut")

        return True, ""

    def _get_commute(self, destination: str) -> Optional[int]:
        """Calcule le temps de trajet via OpenRouteService."""
        try:
            # Geocoder la destination
            geo_url = "https://api.openrouteservice.org/geocode/search"
            headers = {"Authorization": self.ors_key}
            params  = {"text": destination, "size": 1}
            r = requests.get(geo_url, headers=headers, params=params, timeout=10)
            r.raise_for_status()
            coords_dest = r.json()["features"][0]["geometry"]["coordinates"]

            # Geocoder l'adresse de départ
            params["text"] = self.home
            r = requests.get(geo_url, headers=headers, params=params, timeout=10)
            r.raise_for_status()
            coords_home = r.json()["features"][0]["geometry"]["coordinates"]

            # Calculer l'itinéraire
            mode = self.criteria["geography"].get("transport_mode", "driving-car")
            route_url = f"https://api.openrouteservice.org/v2/directions/{mode}"
            body = {"coordinates": [coords_home, coords_dest]}
            r = requests.post(route_url, headers=headers, json=body, timeout=15)
            r.raise_for_status()
            duration_s = r.json()["routes"][0]["summary"]["duration"]
            return int(duration_s / 60)

        except Exception as e:
            log.warning(f"Calcul trajet impossible pour '{destination}': {e}")
            return None


# ──────────────────────────────────────────────────────────────────────────────
# GIT MANAGER
# ──────────────────────────────────────────────────────────────────────────────

class GitManager:
    """Gère le repo Git du CV : clone, branche, commit, push."""

    def __init__(self):
        self.repo_url   = os.environ["GIT_REPO_URL"]
        self.username   = os.environ["GIT_USERNAME"]
        self.email      = os.environ["GIT_EMAIL"]
        self.repo_path  = Path("/tmp/cv-repo")

    def _slug(self, text: str) -> str:
        """Transforme un texte en slug URL-friendly."""
        text = re.sub(r"[^\w\s-]", "", text.lower())
        return re.sub(r"[\s_-]+", "-", text).strip("-")[:40]

    def create_branch_for_offer(self, job: JobOffer) -> str:
        """Clone le repo, crée une branche pour l'offre, retourne le nom de branche."""
        branch = f"cv-{self._slug(job.company)}-{self._slug(job.title)}"

        # Clone si pas encore fait, sinon pull main
        if not self.repo_path.exists():
            subprocess.run(["git", "clone", self.repo_url, str(self.repo_path)],
                           check=True, capture_output=True)

        subprocess.run(["git", "-C", str(self.repo_path),
                        "config", "user.email", self.email], check=True)
        subprocess.run(["git", "-C", str(self.repo_path),
                        "config", "user.name", self.username], check=True)
        subprocess.run(["git", "-C", str(self.repo_path), "checkout", "main"],
                       check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.repo_path), "pull", "origin", "main"],
                       check=True, capture_output=True)
        subprocess.run(["git", "-C", str(self.repo_path),
                        "checkout", "-b", branch], check=True)

        log.info(f"Git: branche '{branch}' créée")
        return branch

    def commit_and_push(self, branch: str, cv_path: Path):
        """Commit le CV adapté et push la branche."""
        subprocess.run(["git", "-C", str(self.repo_path), "add", str(cv_path)],
                       check=True)
        subprocess.run(["git", "-C", str(self.repo_path), "commit",
                        "-m", f"feat: CV adapté pour branche {branch}"],
                       check=True)
        subprocess.run(["git", "-C", str(self.repo_path), "push",
                        "origin", branch], check=True)
        log.info(f"Git: branche '{branch}' poussée")


# ──────────────────────────────────────────────────────────────────────────────
# NOTIFICATEUR EMAIL
# ──────────────────────────────────────────────────────────────────────────────

class Notifier:
    def __init__(self):
        self.host  = os.environ["SMTP_HOST"]
        self.port  = int(os.getenv("SMTP_PORT", 587))
        self.user  = os.environ["SMTP_USER"]
        self.passw = os.environ["SMTP_PASS"]
        self.to    = os.environ["NOTIFY_EMAIL"]

    def send_cv_ready(self, job: JobOffer, branch: str):
        """Envoie une notification quand le CV est prêt."""
        commute_str = f"{job.commute_minutes} min" if job.commute_minutes else "inconnu"
        body = f"""
Nouvelle offre validée par le pipeline !

Poste    : {job.title}
Entreprise : {job.company}
Lieu     : {job.location} ({commute_str} de trajet)
Source   : {job.source}
URL      : {job.url}

CV adapté disponible sur la branche Git : {branch}
GitHub Actions compile le PDF automatiquement.

Bonne chance ! 🚀
        """.strip()

        msg = MIMEText(body, "plain", "utf-8")
        msg["Subject"] = f"[CV Pipeline] Nouveau CV prêt — {job.company} · {job.title}"
        msg["From"]    = self.user
        msg["To"]      = self.to

        with smtplib.SMTP(self.host, self.port) as smtp:
            smtp.starttls()
            smtp.login(self.user, self.passw)
            smtp.send_message(msg)
        log.info(f"Email de notification envoyé à {self.to}")


# ──────────────────────────────────────────────────────────────────────────────
# ORCHESTRATEUR PRINCIPAL
# ──────────────────────────────────────────────────────────────────────────────

class Pipeline:
    def __init__(self):
        self.db       = Database()
        self.imap     = IMAPReader()
        self.parser   = OfferParser()
        self.filt     = OfferFilter()
        self.git      = GitManager()
        self.adapter  = CVAdapter()
        self.notifier = Notifier()

        with open("/config/criteria.yml") as f:
            self.config = yaml.safe_load(f)

    def run_cycle(self):
        """Un cycle complet : fetch → parse → filter → process."""
        emails = self.imap.fetch_unread()
        processed = 0
        max_per_cycle = self.config["pipeline"].get("max_per_cycle", 5)

        for msg in emails:
            if processed >= max_per_cycle:
                log.info(f"Limite de {max_per_cycle} offres/cycle atteinte")
                break

            job = self.parser.parse(msg)
            if not job:
                continue

            # Dédoublonnage
            if job.url and self.db.is_known(job.url):
                log.debug(f"Offre déjà connue: {job.url}")
                continue

            # Filtrage
            accepted, reason = self.filt.evaluate(job)
            job.status       = "accepted" if accepted else "rejected"
            job.reject_reason = reason

            job_id = self.db.upsert_job(job)
            log.info(f"Offre [{job_id}] '{job.title}' @ '{job.company}' "
                     f"→ {job.status}" + (f" ({reason})" if reason else ""))

            if accepted:
                self._process_accepted(job)
                processed += 1

            delay = self.config["pipeline"].get("processing_delay", 5)
            time.sleep(delay)

    def _process_accepted(self, job: JobOffer):
        """Traite une offre acceptée : branche Git + adaptation CV + notification."""
        try:
            # 1. Créer la branche Git
            branch = self.git.create_branch_for_offer(job)
            job.git_branch = branch

            # 2. Lire le Master CV
            master_cv_path = Path("/cv/master-cv.md")
            if not master_cv_path.exists():
                log.error("master-cv.md introuvable dans /cv/ !")
                return

            # 3. Adapter le CV via IA (sans hallucination)
            adapted_cv = self.adapter.adapt(
                master_cv=master_cv_path.read_text(encoding="utf-8"),
                job_offer=f"Poste : {job.title}\nEntreprise : {job.company}\n\n{job.description}"
            )

            # 4. Sauvegarder le CV adapté dans le repo
            cv_output = Path("/tmp/cv-repo/cv.md")
            cv_output.write_text(adapted_cv, encoding="utf-8")
            job.cv_generated_at = datetime.now().isoformat()

            # 5. Commit et push → GitHub Actions prend le relais pour le PDF
            self.git.commit_and_push(branch, cv_output)
            self.db.upsert_job(job)

            # 6. Notification
            self.notifier.send_cv_ready(job, branch)

        except Exception as e:
            log.error(f"Erreur traitement offre '{job.title}': {e}", exc_info=True)

    def run_forever(self):
        """Boucle principale — s'exécute indéfiniment."""
        interval = int(os.getenv("IMAP_CHECK_INTERVAL", 300))
        log.info(f"Pipeline démarré — vérification IMAP toutes les {interval}s")

        while True:
            try:
                self.run_cycle()
            except Exception as e:
                log.error(f"Erreur cycle pipeline: {e}", exc_info=True)
            time.sleep(interval)


if __name__ == "__main__":
    Pipeline().run_forever()
