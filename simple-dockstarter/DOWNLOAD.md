# 📥 SIMPLE DOCKSTARTER HERUNTERLADEN

**Simple DockSTARTer** ist ein **eigenständiges Projekt** - komplett unabhängig vom originalen DockSTARTer!

---

## 🎯 Was ist Simple DockSTARTer?

Ein **modernes, einfaches Python-Tool** zum Verwalten von Docker-Containern:
- ✅ **Nur 1 Skript** (321 Zeilen Python) statt 199 Bash-Skripte
- ✅ **16 vorkonfigurierte Apps** (Jellyfin, Plex, Sonarr, etc.)
- ✅ **Interaktives Menü** - keine komplexen Befehle
- ✅ **100% eigenständig** - funktioniert komplett unabhängig

---

## 📦 DOWNLOAD-OPTIONEN

### Option 1: Als ZIP/TAR Paket (Empfohlen!)

**Für dich (Ersteller):**
```bash
# Erstelle ein eigenständiges Paket
cd ~
tar -czf simple-dockstarter-v1.0.tar.gz -C DockSTARTer simple-dockstarter/

# Jetzt hast du: simple-dockstarter-v1.0.tar.gz
# Diese Datei kannst du verteilen!
```

**Für andere (Installation):**
```bash
# Herunterladen (z.B. von einem Server, USB-Stick, etc.)
# Dann:
tar -xzf simple-dockstarter-v1.0.tar.gz
cd simple-dockstarter
./install.sh
```

---

### Option 2: Als GitHub Repository

**Neues Repository erstellen:**

1. Gehe zu: https://github.com/new
2. Repository-Name: `simple-dockstarter`
3. Public oder Private (deine Wahl)
4. Erstellen

**Dann hochladen:**
```bash
cd ~/DockSTARTer/simple-dockstarter

# Neues Git-Repo initialisieren
rm -rf .git  # Falls vorhanden
git init
git add .
git commit -m "Initial release - Simple DockSTARTer v1.0"

# Mit deinem neuen Repo verbinden (DEIN_USERNAME einsetzen!)
git remote add origin https://github.com/DEIN_USERNAME/simple-dockstarter.git
git branch -M main
git push -u origin main
```

**Andere laden dann so herunter:**
```bash
git clone https://github.com/DEIN_USERNAME/simple-dockstarter.git
cd simple-dockstarter
./install.sh
```

---

### Option 3: Direct Download Script

**Erstelle einen One-Liner Download:**

```bash
# Für andere die es schnell haben wollen:
curl -L https://DEINE-URL/simple-dockstarter.tar.gz | tar xz
cd simple-dockstarter && ./install.sh
```

---

### Option 4: Auf eigenem Server hosten

**Upload zu deinem Server:**
```bash
# ZIP erstellen
cd ~
zip -r simple-dockstarter.zip DockSTARTer/simple-dockstarter/

# Auf Server hochladen (z.B. via SCP)
scp simple-dockstarter.zip user@dein-server.de:/var/www/html/

# Download-Link für andere:
# https://dein-server.de/simple-dockstarter.zip
```

---

## 🚀 SCHNELL-INSTALLATION (für Nutzer)

### Wenn du das Paket hast:

```bash
# 1. Entpacken
tar -xzf simple-dockstarter-v1.0.tar.gz
# oder
unzip simple-dockstarter.zip

# 2. Ins Verzeichnis
cd simple-dockstarter

# 3. Installieren
./install.sh

# 4. Starten
./dockstarter.py
```

**Das war's!** ✅

---

## 📋 WAS WIRD BENÖTIGT?

Nutzer brauchen nur:
- ✅ Linux, macOS oder WSL (Windows)
- ✅ Docker (wird automatisch installiert wenn nötig)
- ✅ Python 3.8+ (meist vorinstalliert)
- ✅ Die Simple DockSTARTer Dateien

**Keine weiteren Abhängigkeiten!**

---

## 🌐 VERTEILEN - Best Practices

### Für kleine Gruppe (Freunde/Familie):
→ **ZIP/TAR auf USB-Stick** oder via Cloud (Dropbox, Google Drive)

### Für öffentliche Nutzung:
→ **GitHub Repository** (kostenlos, einfach Updates)

### Für eigene Website:
→ **Direkter Download-Link** von deinem Server

---

## 📝 VERSION & UPDATES

**Versionen nummerieren:**
```bash
# Bei Updates neue Version erstellen
tar -czf simple-dockstarter-v1.1.tar.gz simple-dockstarter/
```

**Changelog führen:**
Erstelle `CHANGELOG.md`:
```markdown
# Changelog

## v1.0 (2025-01-28)
- Initial release
- 16 vorkonfigurierte Apps
- Interaktives Python-Menü

## v1.1 (2025-XX-XX)
- Neue Apps hinzugefügt
- Bug fixes
```

---

## 🔐 WICHTIG FÜR SICHERHEIT

Beim Verteilen beachten:
- ✅ Keine persönlichen Daten in den Dateien
- ✅ Keine Passwörter oder API-Keys
- ✅ `config.yml`, `.env`, `data/` NICHT mit verteilen!
- ✅ Nur Quellcode und Templates teilen

**Vor dem Erstellen des Pakets:**
```bash
# Lösche generierte Dateien
cd ~/DockSTARTer/simple-dockstarter
rm -f config.yml .env docker-compose.yml
rm -rf data/

# Jetzt Paket erstellen
cd ..
tar -czf simple-dockstarter-v1.0.tar.gz simple-dockstarter/
```

---

## 💡 BEISPIEL: Vollständige Veröffentlichung

**1. Vorbereiten:**
```bash
cd ~/DockSTARTer/simple-dockstarter
rm -f config.yml .env docker-compose.yml
rm -rf data/
```

**2. Paket erstellen:**
```bash
cd ~
tar -czf simple-dockstarter-v1.0.tar.gz -C DockSTARTer simple-dockstarter/
```

**3. GitHub Repository erstellen und hochladen:**
```bash
cd ~/DockSTARTer/simple-dockstarter
git init
git add .
git commit -m "v1.0 - Initial Release"
git remote add origin https://github.com/DEIN_USERNAME/simple-dockstarter.git
git push -u origin main
```

**4. Release erstellen auf GitHub:**
- Gehe zu deinem Repo → "Releases" → "Create new release"
- Tag: `v1.0`
- Lade `simple-dockstarter-v1.0.tar.gz` hoch

**Fertig!** Andere können es jetzt herunterladen! 🎉

---

## 📞 SUPPORT FÜR NUTZER

Wenn du Simple DockSTARTer verteilst, sage den Nutzern:

```
Probleme? Prüfe diese Dateien:
- START.md      - Absolute Anfänger
- QUICKSTART.md - 5-Minuten-Guide
- README.md     - Vollständige Doku
```

---

**Simple DockSTARTer - Eigenständig, einfach, effektiv!** 🐳
