# Simple DockSTARTer 🐳

Eine **radikal vereinfachte** Alternative zum originalen DockSTARTer - entwickelt für maximale Benutzerfreundlichkeit und Wartbarkeit.

## 🎯 Was ist Simple DockSTARTer?

Simple DockSTARTer ist ein modernes Python-Tool zur einfachen Verwaltung von Docker-Containern. Es reduziert die Komplexität des originalen DockSTARTer (199 Bash-Skripte, ~13.000 Zeilen Code) auf **ein einziges Python-Skript** mit ~400 Zeilen.

### Vergleich: Original vs. Simple

| Feature | Original DockSTARTer | Simple DockSTARTer |
|---------|---------------------|-------------------|
| Anzahl Dateien | 199 Skripte | 1 Python-Skript |
| Zeilen Code | ~13.000 | ~400 |
| Sprache | Bash | Python 3 |
| Themes | 12 Themes | Modernes UI |
| Multi-Instance | Ja | Nein (KISS Prinzip) |
| Komplexität | Sehr hoch | Sehr niedrig |
| Wartbarkeit | Schwierig | Einfach |
| Lernkurve | Steil | Flach |

## ✨ Features

- ✅ **Interaktives CLI** - Schöne Benutzeroberfläche mit InquirerPy
- ✅ **Ein Skript** - Alles in einer Datei, leicht zu verstehen
- ✅ **Einfache App-Definitionen** - Klare YAML-Dateien für jede App
- ✅ **Docker Compose Generator** - Automatische Generierung aus Templates
- ✅ **10+ vorkonfigurierte Apps** - Jellyfin, Sonarr, Radarr, Plex, etc.
- ✅ **Keine komplexen Features** - Fokus auf das Wesentliche
- ✅ **Modern** - Python 3, Rich Terminal UI, Type Hints

## 📋 Voraussetzungen

- **Docker** - [Installation](https://docs.docker.com/get-docker/)
- **Python 3.8+** - Meist vorinstalliert
- **pip3** - Python Package Manager

## 🚀 Installation

### Schritt 0: Dateien herunterladen

**Simple DockSTARTer ist ein eigenständiges Projekt!**

**Hast du die Dateien bereits?** Prüfe ob du diese siehst:
- `dockstarter.py` ✅
- `install.sh` ✅
- `apps/` Verzeichnis ✅

**Noch keine Dateien?** → Siehe **DOWNLOAD.md** für:
- ZIP/TAR Download
- GitHub Repository erstellen
- Distribution an andere

---

### Methode 1: Automatische Installation (empfohlen!)

```bash
# Gehe zum simple-dockstarter Verzeichnis
# (Pfad kann bei dir anders sein!)
cd simple-dockstarter

# Führe das Installations-Skript aus
./install.sh

# Fertig! Starten mit:
./dockstarter.py
```

Das `install.sh` Skript macht automatisch:
- ✅ Prüft ob Docker installiert ist (installiert es wenn nötig)
- ✅ Installiert Python-Abhängigkeiten
- ✅ Macht das Skript ausführbar
- ✅ Fragt ob du einen globalen `simple-ds` Befehl willst

### Methode 2: Manuelle Installation

Falls du lieber Schritt für Schritt vorgehen willst:

```bash
# 1. Gehe zum Verzeichnis (Pfad anpassen!)
cd simple-dockstarter

# 2. Python-Abhängigkeiten installieren
pip3 install --user InquirerPy rich PyYAML

# 3. Skript ausführbar machen
chmod +x dockstarter.py install.sh

# 4. Starten
./dockstarter.py
```

### Optional: Globaler Befehl

Wenn du von überall `simple-ds` eingeben willst:

```bash
# Im simple-dockstarter Verzeichnis:
sudo ln -s $(pwd)/dockstarter.py /usr/local/bin/simple-ds

# Dann von überall:
simple-ds
```

## 📖 Verwendung

### Erstmalige Einrichtung

1. **Starten:**
   ```bash
   ./dockstarter.py
   ```

2. **Im Menü:**
   - Wähle `📦 Select Apps` um Apps auszuwählen
   - Wähle `⚙️ Configure Settings` für Grundeinstellungen
   - Wähle `🔨 Generate docker-compose.yml` zum Generieren
   - Wähle `🚀 Start Containers` zum Starten

### Menü-Optionen

```
📦 Select Apps              - Apps auswählen (Checkbox-Liste)
⚙️ Configure Settings       - Timezone, Data-Verzeichnis etc. konfigurieren
🔨 Generate docker-compose  - docker-compose.yml erstellen
📊 Show Status             - Aktuellen Status anzeigen
🚀 Start Containers        - Container starten (docker compose up -d)
🛑 Stop Containers         - Container stoppen (docker compose down)
🔄 Restart Containers      - Container neu starten
⬇️ Pull Latest Images      - Neueste Images herunterladen
📝 View Logs              - Container-Logs anzeigen
❌ Quit                    - Beenden
```

### Beispiel-Workflow

```bash
# Starten
./dockstarter.py

# 1. Apps auswählen
#    → Wähle "Select Apps"
#    → Markiere: Jellyfin, Sonarr, Radarr (mit Leertaste)
#    → Enter drücken

# 2. Einstellungen konfigurieren (optional)
#    → Wähle "Configure Settings"
#    → Timezone: Europe/Berlin
#    → Data Dir: /home/user/docker-data

# 3. docker-compose.yml generieren
#    → Wähle "Generate docker-compose.yml"

# 4. Container starten
#    → Wähle "Start Containers"

# 5. Zugriff auf Apps
#    → Jellyfin: http://localhost:8096
#    → Sonarr: http://localhost:8989
#    → Radarr: http://localhost:7878
```

## 📦 Verfügbare Apps

Aktuell vorkonfiguriert:

- **Jellyfin** - Free Media Server (Plex Alternative)
- **Plex** - Populärer Media Server
- **Sonarr** - TV-Serien Management
- **Radarr** - Film Management
- **Transmission** - BitTorrent Client
- **Portainer** - Docker UI Management
- **Homer** - Dashboard für Services
- **Nginx** - Web Server / Reverse Proxy
- **Pi-hole** - Network-wide Ad Blocking
- **Home Assistant** - Smart Home Platform

## 🔧 Eigene Apps hinzufügen

Apps werden als einfache YAML-Dateien in `apps/` definiert:

```bash
# Neue App erstellen
nano apps/meine-app.yml
```

**Beispiel-Format:**

```yaml
description: "Meine App - Kurze Beschreibung"
image: "dockerhub/image:latest"
ports:
  - "8080:80"
volumes:
  - "${DATA_DIR}/meine-app:/config"
environment:
  - PUID=${PUID}
  - PGID=${PGID}
  - TZ=${TZ}
restart: unless-stopped
```

**Unterstützte Felder:**

- `description` - Beschreibung (wird im Menü angezeigt)
- `image` - Docker Image
- `ports` - Port-Mappings (Liste)
- `volumes` - Volume-Mounts (Liste)
- `environment` - Umgebungsvariablen (Liste)
- `restart` - Restart-Policy
- `networks` - Netzwerke (Optional)
- `depends_on` - Abhängigkeiten (Optional)
- `devices` - Device-Mounts (Optional)
- `privileged` - Privileged Mode (Optional)
- `cap_add` - Capabilities (Optional)
- `labels` - Container Labels (Optional)

## 📁 Verzeichnisstruktur

```
simple-dockstarter/
├── dockstarter.py          # Hauptskript (alles in einer Datei!)
├── apps/                   # App-Definitionen (YAML)
│   ├── jellyfin.yml
│   ├── sonarr.yml
│   ├── radarr.yml
│   └── ...
├── config.yml             # Benutzer-Konfiguration (auto-generiert)
├── docker-compose.yml     # Generiert aus ausgewählten Apps
├── .env                   # Umgebungsvariablen (auto-generiert)
├── data/                  # Container-Daten (wird erstellt)
│   ├── jellyfin/
│   ├── sonarr/
│   └── ...
└── README.md             # Diese Datei
```

## 🔍 Konfiguration

Die Konfiguration wird in `config.yml` gespeichert:

```yaml
selected_apps:
  - jellyfin
  - sonarr
  - radarr
user_id: 1000
group_id: 1000
timezone: Europe/Berlin
data_dir: /home/user/DockSTARTer/simple-dockstarter/data
```

Diese Datei wird automatisch erstellt und kann auch manuell bearbeitet werden.

## 🐛 Troubleshooting

### Docker nicht gefunden

```bash
# Docker installieren (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Neu einloggen erforderlich!
```

### Python-Pakete fehlen

```bash
pip3 install InquirerPy rich PyYAML

# Oder mit Virtual Environment
python3 -m venv venv
source venv/bin/activate
pip install InquirerPy rich PyYAML
```

### Ports bereits belegt

```bash
# Prüfen welcher Prozess Port verwendet
sudo lsof -i :8096

# Port in App-Definition ändern
nano apps/jellyfin.yml
# Ändere "8096:8096" zu "8097:8096"
```

### Permission Denied

```bash
# Skript ausführbar machen
chmod +x dockstarter.py

# Oder mit Python direkt
python3 dockstarter.py
```

### Container starten nicht

```bash
# Logs prüfen
docker compose logs

# Einzelnen Container prüfen
docker logs container-name

# Compose-Datei validieren
docker compose config
```

## 🆚 Warum Simple DockSTARTer?

Simple DockSTARTer wurde entwickelt als **radikal vereinfachte Alternative** zu komplexen Docker-Management-Tools:

### Design-Philosophie:

- ✅ **KISS-Prinzip** - Keep It Simple, Stupid
- ✅ **Ein Skript** - Alles in 321 Zeilen Python
- ✅ **Wartbar** - Python ist lesbarer und moderner als Bash
- ✅ **Schnell** - Kein Overhead durch Script-Loading
- ✅ **Modern** - Aktuelle Python-Libraries
- ✅ **Fokussiert** - Nur was wirklich gebraucht wird
- ✅ **Erweiterbar** - Eigene Apps in 2 Minuten hinzugefügt
- ✅ **Eigenständig** - Keine komplexen Abhängigkeiten

### Für wen ist es gedacht?

- **Anfänger** - Die Docker nutzen wollen ohne Befehle zu lernen
- **Pragmatiker** - Die funktionierende Lösungen statt Features wollen
- **Bastler** - Die eigene Apps einfach hinzufügen wollen
- **Minimalisten** - Die keine 199-Skript-Monster wollen

## 🤝 Anpassen & Erweitern

Eigene Apps hinzufügen ist super einfach:

1. YAML-Datei in `apps/` erstellen
2. Format von anderen Apps übernehmen
3. Fertig - erscheint automatisch im Menü!

Das Skript ist bewusst einfach gehalten, damit **jeder** es verstehen und anpassen kann.

## 📝 Lizenz

**MIT License** - Frei verwendbar für private und kommerzielle Projekte!

```
Copyright (c) 2025 Simple DockSTARTer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software.
```

## 🙏 Credits & Inspiration

- **Inspiriert von** - Original DockSTARTer Projekt (Idee der einfachen Container-Verwaltung)
- **Docker Images** - Hauptsächlich von [LinuxServer.io](https://fleet.linuxserver.io/)
- **Python Libraries** - [InquirerPy](https://github.com/kazhala/InquirerPy) (Interaktive CLI), [Rich](https://github.com/Textualize/rich) (Terminal UI)
- **Community** - Danke an alle die Docker und Open Source möglich machen!

## 📚 Weiterführende Links

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [LinuxServer.io Images](https://fleet.linuxserver.io/)

---

**Made with ❤️ for simplicity**

*Simple is better than complex. Complex is better than complicated.* - The Zen of Python
