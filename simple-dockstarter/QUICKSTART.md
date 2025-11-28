# Quick Start Guide 🚀

Schnellstart-Anleitung für Simple DockSTARTer in 5 Minuten.

## 0️⃣ Dateien herunterladen (falls nötig)

**⚠️ Hinweis:** Simple DockSTARTer ist eigenständig und noch nicht im offiziellen Repository!

**Prüfe ob du die Dateien schon hast:**
```bash
ls ~/DockSTARTer/simple-dockstarter/
```

**Siehst du Dateien (dockstarter.py, install.sh, apps/, etc.)?**
→ Perfekt! Springe zu Schritt 1️⃣

**Keine Dateien vorhanden?**
→ Siehe **DOWNLOAD.md** für Download-Optionen

---

## 1️⃣ Installation (2 Minuten)

**So einfach geht's - Schritt für Schritt:**

### Schritt 1: Terminal öffnen
Öffne ein Terminal auf deinem System

### Schritt 2: Zum Verzeichnis gehen
```bash
cd ~/DockSTARTer/simple-dockstarter
```

### Schritt 3: Installations-Skript ausführen
```bash
./install.sh
```

**Das Skript wird dich fragen:**
- "Docker installieren?" → Tippe `y` und Enter (wenn Docker noch nicht installiert ist)
- "Globalen Befehl erstellen?" → Tippe `y` für ja oder `n` für nein

**Was automatisch passiert:**
- ✅ Prüft ob Docker installiert ist (installiert es wenn gewünscht)
- ✅ Installiert Python-Pakete (InquirerPy, Rich, PyYAML)
- ✅ Macht das Skript ausführbar
- ✅ Zeigt dir alle verfügbaren Apps

**Nach der Installation siehst du eine Bestätigung!**

## 2️⃣ Erste Schritte (3 Minuten)

### Simple DockSTARTer starten

```bash
./dockstarter.py
# oder (wenn global installiert):
simple-ds
```

### Im Menü:

**Schritt 1: Apps auswählen**
```
📦 Select Apps
→ Wähle deine Apps mit [Leertaste]
→ Bestätige mit [Enter]
```

Beispiel-Setup für Media Server:
- [x] Jellyfin (Media Server)
- [x] Sonarr (TV Shows)
- [x] Radarr (Movies)
- [x] Jackett (Indexer)
- [x] Transmission (Download)

**Schritt 2: Einstellungen (Optional)**
```
⚙️ Configure Settings
→ Timezone: Europe/Berlin
→ Data Dir: (Standard OK)
```

**Schritt 3: Generate docker-compose.yml**
```
🔨 Generate docker-compose.yml
→ Wartet bis "✓ Generated..."
```

**Schritt 4: Container starten**
```
🚀 Start Containers
→ Wartet bis alle Container laufen
```

## 3️⃣ Zugriff auf deine Apps

Nach dem Start sind deine Apps verfügbar:

| App | URL | Standard-Port |
|-----|-----|---------------|
| Jellyfin | http://localhost:8096 | 8096 |
| Sonarr | http://localhost:8989 | 8989 |
| Radarr | http://localhost:7878 | 7878 |
| Portainer | http://localhost:9000 | 9000 |
| Transmission | http://localhost:9091 | 9091 |
| Jackett | http://localhost:9117 | 9117 |
| Pi-hole | http://localhost:8053 | 8053 |
| Home Assistant | http://localhost:8123 | 8123 |
| Grafana | http://localhost:3000 | 3000 |
| Nextcloud | http://localhost:8081 | 8081 |

**Tipp:** Ersetze `localhost` mit deiner Server-IP wenn du von einem anderen Gerät zugreifst.

## 4️⃣ Häufige Befehle

```bash
# Container status prüfen
docker compose ps

# Logs anzeigen
docker compose logs -f

# Einzelne App-Logs
docker compose logs -f jellyfin

# Container neu starten
docker compose restart

# Container stoppen
docker compose down

# Updates holen
docker compose pull
docker compose up -d
```

## 5️⃣ Beispiel-Setups

### Media Server Setup
```
✓ Jellyfin      (Media Server)
✓ Sonarr        (TV Management)
✓ Radarr        (Movie Management)
✓ Jackett       (Indexer)
✓ Transmission  (Downloader)
✓ Tautulli      (Monitoring)
```

### Home Server Setup
```
✓ Portainer     (Docker UI)
✓ Homer         (Dashboard)
✓ Pi-hole       (Ad Blocker)
✓ Nextcloud     (Cloud Storage)
✓ Nginx         (Reverse Proxy)
```

### Smart Home Setup
```
✓ Home Assistant  (Smart Home)
✓ Grafana        (Dashboards)
✓ Portainer      (Management)
```

## 6️⃣ Nächste Schritte

1. **Apps konfigurieren**
   - Öffne die Web-Interfaces
   - Folge den Setup-Wizards

2. **Daten-Verzeichnisse anpassen**
   - Bearbeite `config.yml`
   - Ändere `data_dir` auf deine gewünschte Location

3. **Eigene Apps hinzufügen**
   - Erstelle neue YAML in `apps/`
   - Siehe README für Format

4. **Automatische Updates**
   - Installiere Watchtower
   - Container werden automatisch aktualisiert

## 🆘 Probleme?

### Port bereits belegt
```bash
# Port-Konflikt lösen
nano apps/app-name.yml
# Ändere Port z.B. "8096:8096" → "8097:8096"
```

### Container startet nicht
```bash
# Logs prüfen
docker compose logs app-name

# Neustart erzwingen
docker compose down
docker compose up -d
```

### Permissions Fehler
```bash
# Prüfe PUID/PGID
cat .env | grep PUID

# Sollte deine User-ID sein:
id -u  # Deine PUID
id -g  # Deine PGID
```

## 📚 Mehr Infos

- **Vollständige Dokumentation:** [README.md](README.md)
- **Eigene Apps erstellen:** Siehe README → "Eigene Apps hinzufügen"
- **Docker Befehle:** [Docker Compose Docs](https://docs.docker.com/compose/)

---

**Happy Docking! 🐳**
