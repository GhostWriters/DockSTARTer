# 🚀 WIE STARTE ICH?

**Für absolute Anfänger - Schritt für Schritt**

---

## Was ist das?

Simple DockSTARTer hilft dir, einfach Docker-Container (Apps wie Jellyfin, Plex, etc.) zu installieren und zu verwalten - **ohne komplizierte Befehle**.

---

## ⚡ Schnellstart (4 Schritte)

### 0️⃣ Dateien herunterladen (wenn du sie noch nicht hast)

**⚠️ Wichtig:** Simple DockSTARTer ist eigenständig, nicht im offiziellen DockSTARTer!

**Hast du die Dateien schon?** Prüfe mit:
```bash
ls ~/DockSTARTer/simple-dockstarter/
```

**Siehst du Dateien wie dockstarter.py, install.sh, apps/?**
→ Ja! Springe zu Schritt 1️⃣

**Nichts da?**
→ Schau in **DOWNLOAD.md** - dort steht wie du sie bekommst (ZIP, GitHub, etc.)

---

### 1️⃣ Terminal öffnen

**Linux/Mac:**
- Drücke `Strg + Alt + T` oder suche nach "Terminal"

**Windows (WSL):**
- Suche nach "Ubuntu" oder "WSL" im Startmenü

---

### 2️⃣ Installieren

Kopiere diese Zeilen ins Terminal (einzeln oder alle auf einmal):

```bash
cd ~/DockSTARTer/simple-dockstarter
./install.sh
```

**Was passiert:**
- Das Skript prüft dein System
- Fragt ob Docker installiert werden soll (wenn nötig)
- Installiert automatisch alles Benötigte
- **Dauert 2-3 Minuten**

---

### 3️⃣ Starten

```bash
./dockstarter.py
```

**Jetzt siehst du ein Menü!** 🎉

---

## 📱 Im Menü - Was machen?

Du siehst so ein Menü:

```
Simple DockSTARTer

What would you like to do?
> 📦 Select Apps
  ⚙️  Configure Settings
  🔨 Generate docker-compose.yml
  📊 Show Status
  🚀 Start Containers
  ❌ Quit
```

### Schritt-für-Schritt:

#### **Schritt A: Apps auswählen**
1. Wähle `📦 Select Apps` (mit Pfeiltasten `↑↓` und `Enter`)
2. Du siehst eine Liste mit Apps
3. **Mit LEERTASTE** Apps markieren (✓)
4. Mit `Enter` bestätigen

**Empfehlung für Anfänger:**
- ✓ Portainer (Docker-Verwaltung)
- ✓ Jellyfin (Media Server)

#### **Schritt B: Einstellungen** (Optional)
1. Wähle `⚙️ Configure Settings`
2. Timezone eingeben (z.B. `Europe/Berlin`)
3. Data Dir: Einfach `Enter` drücken (Standard ist OK)

#### **Schritt C: Generieren**
1. Wähle `🔨 Generate docker-compose.yml`
2. Warte bis "✓ Generated..." erscheint

#### **Schritt D: Starten!**
1. Wähle `🚀 Start Containers`
2. Warte ~1 Minute
3. **FERTIG!** 🎉

---

## 🌐 Apps öffnen

Öffne deinen Browser und gehe zu:

| App | URL |
|-----|-----|
| Portainer | http://localhost:9000 |
| Jellyfin | http://localhost:8096 |
| Sonarr | http://localhost:8989 |
| Radarr | http://localhost:7878 |

**Tipp:** Wenn du auf einem Server arbeitest, ersetze `localhost` mit der IP-Adresse deines Servers!

---

## ❓ Häufige Fragen

### "Ich sehe keine Apps im Menü!"
→ Warte, sie werden geladen. Wenn nichts kommt: Prüfe ob `apps/` Ordner existiert

### "Docker not found!"
→ Das Installations-Skript hätte Docker installieren sollen. Führe `./install.sh` nochmal aus

### "Permission denied"
→ Führe aus: `chmod +x dockstarter.py install.sh`

### "Port already in use"
→ Ein anderes Programm nutzt den Port. In `apps/app-name.yml` kannst du den Port ändern

### "Wie stoppe ich Container?"
→ Im Menü: `🛑 Stop Containers` wählen

### "Wo sind meine Daten?"
→ Im Ordner `data/` im simple-dockstarter Verzeichnis

---

## 🆘 Hilfe!

**Wenn etwas nicht funktioniert:**

1. Schaue in: `QUICKSTART.md` (ausführlicher)
2. Schaue in: `README.md` (alle Details)
3. Prüfe Logs: `docker compose logs`

---

## 🎯 Das war's!

**So einfach:**
1. `./install.sh` ausführen
2. `./dockstarter.py` starten
3. Apps auswählen
4. Generieren
5. Starten
6. Im Browser öffnen

**Fertig!** 🚀

---

**Viel Spaß mit deinen Docker-Apps!** 🐳
