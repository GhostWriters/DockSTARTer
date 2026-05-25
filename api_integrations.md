# API Integrations — Inventory, Storage Design & Wiring Matrix

Investigation of how API keys and secrets from individual apps in DockSTARTer could be collected, stored, and used to automate app-to-app integration.

## Current state

Nothing exists today. No script references API keys, and `compose/.env.app.*` files don't carry them. This document covers a greenfield design.

---

## Where each app stores its key

| App | File (under `${DOCKER_VOLUME_CONFIG}/<app>/`) | Format | Field |
|---|---|---|---|
| **sonarr / radarr / lidarr / readarr / prowlarr** | `config.xml` | XML | `<ApiKey>...</ApiKey>` (32-hex) |
| **bazarr** | `config/config.ini` | INI | `[auth] apikey = ...` |
| **jackett** | `Jackett/ServerConfig.json` | JSON | `"APIKey"` |
| **sabnzbd** | `sabnzbd.ini` | INI | `api_key = ...` + `nzb_key = ...` (two separate keys) |
| **nzbget** | `nzbget.conf` | INI-ish | `ControlPassword` (password, not key) |
| **nzbhydra2** | `nzbhydra.yml` | YAML | `apiKey` |
| **qbittorrent** | `qBittorrent.conf` | INI | No API key — username/password (`WebUI\Username`, `WebUI\Password_PBKDF2`) |
| **transmission** | `settings.json` | JSON | `rpc-username` / `rpc-password` |
| **deluge** | `core.conf` + `auth` | mixed | `auth` file: `user:pass:level` |
| **tautulli** | `config.ini` | INI | `[General] api_key` |
| **overseerr / jellyseerr** | `settings.json` | JSON | `clientId`, `vapidPrivate`, `apiKey` |
| **jellyfin** | `data/jellyfin.db` (SQLite) | DB | `ApiKeys` table — generated, not file-readable |
| **plex** | API exchange via `plex.tv` login | n/a | token from auth flow |

Key fact: **most of these files don't exist until the container has started once.** Designs need to handle "first run hasn't happened yet" as a normal state.

---

## Collection approaches

### Approach A: Passive scraping (read after first run)

A new script `collect_api_keys.sh` that runs after `ds -c up`:

```bash
# pseudo
for app in sonarr radarr lidarr prowlarr; do
  config="${DOCKER_VOLUME_CONFIG}/${app}/config.xml"
  [[ -f $config ]] || continue
  key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$config")
  store_key "$app" "$key"
done
```

**Pros**
- Zero coordination with containers — just file I/O.
- Survives the app regenerating its key (re-run picks up the new value).
- No secrets pre-seeding, no race conditions.

**Cons**
- Needs per-app parsers (XML/INI/JSON/YAML/SQLite).
- Has to wait for first run. Need a "have you started yet" gate or just no-op gracefully.
- Permission: configs are owned by `PUID:PGID`, so reads need `sudo` or correct user.

### Approach B: Active extraction via each app's API

After first run, hit each app's own endpoint (most expose key under basic auth or initial setup):

| App | Endpoint |
|---|---|
| sonarr/radarr | `GET /initialize.js` returns `apiKey` in JS blob (no auth on this endpoint) |
| prowlarr | same |
| sabnzbd | API key in UI but also `sabnzbd.ini` |
| jackett | `GET /UI/Dashboard` HTML scrape, or `ServerConfig.json` |

**Pros**: works even if config files have weird ownership.
**Cons**: HTTP plumbing, container-must-be-running gate, harder than reading a file. Generally worse than A.

### Approach C: Pre-seed before first run

Generate keys yourself, write into config files before container starts. The arr apps will use your value instead of generating one.

```bash
# Before docker compose up
mkdir -p "${DOCKER_VOLUME_CONFIG}/sonarr"
key=$(openssl rand -hex 16)
cat > "${DOCKER_VOLUME_CONFIG}/sonarr/config.xml" <<EOF
<Config>
  <ApiKey>${key}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
</Config>
EOF
chown -R "${PUID}:${PGID}" "${DOCKER_VOLUME_CONFIG}/sonarr"
```

**Pros**: deterministic — keys known from t=0, can be referenced by other apps in the same `up`.
**Cons**: brittle (apps validate config schemas; minimal skeleton may not be enough); only works for fresh installs, would overwrite real configs on existing setups.

**Verdict**: only usable for greenfield. Combine with A: pre-seed if no config exists, otherwise scrape.

### Approach D: Hybrid (recommended)

A new sub-command `ds --collect-keys` (or auto-run as a hook after `ds -c up`):

1. For each known app, if config file exists → **scrape** (Approach A).
2. If config doesn't exist → **skip**, log "run app once first."
3. Optionally, for selected apps the user opts into → **pre-seed** before first run (Approach C).
4. Store results in a dedicated state file (see Storage below).
5. Re-run idempotently. If a stored key differs from the scraped one, the file wins (app regenerated; update store).

---

## Storage — three viable locations

### Option 1: `${APPLICATION_STATE_FOLDER}/api_keys.toml`

Centralized, structured, mode 0600:

```toml
[sonarr]
api_key = "abc123..."
discovered_at = 2026-05-25T18:30:00Z

[sabnzbd]
api_key = "def456..."
nzb_key = "789ghi..."

[qbittorrent]
username = "admin"
password_hash = "@ByteArray(...)"
```

**Pros**: lives outside compose, single source of truth, easy to query (`tomlq`), survives compose teardown.
**Cons**: yet another state file; needs a fetch helper script.

### Option 2: `${COMPOSE_FOLDER}/.env.app.keys` (new sidecar)

Use the existing `.env.app.*` convention:

```sh
SONARR_API_KEY='abc123...'
RADARR_API_KEY='def456...'
SABNZBD_API_KEY='...'
SABNZBD_NZB_KEY='...'
```

**Pros**: leverages existing mechanism, compose-interpolatable directly. Templates can reference `${SONARR_API_KEY?}` in *any* other app's env.
**Cons**: not tied to a specific container — would need a naming convention to avoid collision with `<APP>:` vars. Probably need new prefix like `KEYS__SONARR_API_KEY`.

### Option 3: Docker secrets

```yaml
secrets:
  sonarr_api_key:
    file: ${APPLICATION_STATE_FOLDER}/secrets/sonarr_api_key
```

**Pros**: proper secret handling, not exposed via `docker inspect env`, file-mode 0400 in container.
**Cons**: heavier; many apps don't read secrets natively (need entrypoint shims to convert to env); not all configs accept env-injected keys.

**Best pick**: **Option 2** for compose-time interpolation + **Option 1** as the canonical record (toml is the source, env file is derived/regenerated). Two-file pattern keeps each format doing what it's good at.

---

## Producers — apps that generate a key/secret worth collecting

Based on the 23 apps shipped in this checkout, with broader template apps in *italics*.

| App | Secret type | Storage location | Notes |
|---|---|---|---|
| **sonarr** | API key (32-hex) | `${CONFIG}/sonarr/config.xml` → `<ApiKey>` | Also exposed unauthenticated at `GET /initialize.js` |
| **radarr** | API key | `${CONFIG}/radarr/config.xml` → `<ApiKey>` | Same |
| **lidarr** | API key | `${CONFIG}/lidarr/config.xml` → `<ApiKey>` | Same |
| **prowlarr** | API key | `${CONFIG}/prowlarr/config.xml` → `<ApiKey>` | Same — also a *consumer* (needs arr keys) |
| **jackett** | API key | `${CONFIG}/jackett/Jackett/ServerConfig.json` → `"APIKey"` | Plus optional `AdminPassword` (hashed) |
| **sabnzbd** | `api_key` + `nzb_key` | `${CONFIG}/sabnzbd/sabnzbd.ini` | Two distinct keys — `nzb_key` is for adding NZBs, `api_key` for everything else |
| **nzbhydra2** | API key | `${CONFIG}/nzbhydra2/nzbhydra.yml` → `apiKey` | Also `adminUsername`/`adminPassword` |
| **qbittorrent** | WebUI username + password (PBKDF2 hash) | `${CONFIG}/qbittorrent/qBittorrent/config/qBittorrent.conf` → `WebUI\Username`, `WebUI\Password_PBKDF2` | Not an API key — basic auth. Default `admin` / random pw printed to logs on first run |
| **jellyfin** | API token | `${CONFIG}/jellyfin/data/jellyfin.db` (SQLite `ApiKeys` table) | Generated via UI or `POST /Users/AuthenticateByName` then `POST /Auth/Keys` |
| **grafana** | Admin password, then API tokens | `${CONFIG}/grafana/grafana.db` | Admin pw set via `GF_SECURITY_ADMIN_PASSWORD` env, tokens minted post-setup |
| **influxdb** | Admin token | `${CONFIG}/influxdb/...` | Set via `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` env on first run |
| **mariadb** | Root password | env-only (`MYSQL_ROOT_PASSWORD`) | Set at container init, not stored in config |
| **portaineragent** | `AGENT_SECRET` | env-only | Shared with portainer master — must match on both sides |
| **organizr** | Registration password + DB | `${CONFIG}/organizr/www/Dashboard/databases/database.db` | Set during web setup |
| **flame** | UI password | `${CONFIG}/flame/data/db.sqlite` | Set via `PASSWORD` env |
| **gluetun** | Control server API key *(optional)* | env: `HTTP_CONTROL_SERVER_AUTH` | Off by default; only relevant if exposing control API |
| **watchtower** | HTTP API token *(optional)* | env: `WATCHTOWER_HTTP_API_TOKEN` | Only used if running with `--http-api-update` |
| **speedtest** (tracker) | `APP_KEY` (Laravel) + admin pw | env + DB | Mostly self-contained, no consumers |

**No secrets worth collecting**: flaresolverr, xteve, openspeedtest, httpserver, recyclarr (consumer-only).

---

## Consumers — apps that need other apps' keys

| App | Needs keys from | Integration purpose |
|---|---|---|
| **sonarr** | jackett **or** prowlarr **or** nzbhydra2 → indexer search; sabnzbd / qbittorrent → download client; bazarr (reverse) | Indexer + download client wiring |
| **radarr** | same as sonarr | same |
| **lidarr** | same as sonarr | same |
| **prowlarr** | **sonarr, radarr, lidarr** (+readarr, whisparr) | Push indexer configs into each arr via `/api/v1/applications` |
| **recyclarr** | **sonarr, radarr** | Sync Trash Guides quality profiles & custom formats |
| *bazarr* | **sonarr, radarr** | Pull library list, fetch subtitles for tracked items |
| *overseerr / jellyseerr* | **sonarr, radarr, jellyfin/plex** | Request system — submits adds to arrs, reads library from media server |
| *tautulli* | plex/jellyfin | Stats/notification daemon |
| **nzbhydra2** | jackett (optional, as a sub-indexer) | Aggregates jackett indexers |
| **grafana** | influxdb, prometheus | Datasource provisioning |
| *telegraf* | influxdb | Writes metrics to influx |
| *portainer master* | **portaineragent** (`AGENT_SECRET`) | Connects master to each agent node |
| **organizr** | all web UIs (optional API keys for "tab health checks") | Dashboard with auth-proxying |
| **flame** | all web UIs (just URLs, no keys needed) | Bookmark dashboard |
| *homarr / homepage* | **sonarr, radarr, lidarr, sabnzbd, qbittorrent, jellyfin, prowlarr, tautulli, jackett** | Dashboards with live queue/library stats per app |
| *lunasea / nzb360* (mobile) | sonarr, radarr, lidarr, sabnzbd, tautulli | Mobile control apps — out of scope but consume the same keys |

---

## Integration matrix — who calls whom

Reading row → column ("row needs column's key"):

|              | sonarr | radarr | lidarr | prowlarr | jackett | sab | qbit | nzbhydra2 | jellyfin | influxdb | portaineragent |
|--------------|:------:|:------:|:------:|:--------:|:-------:|:---:|:----:|:---------:|:--------:|:--------:|:--------------:|
| sonarr       |   —    |        |        |          |    ✓    |  ✓  |  ✓   |     ✓     |          |          |                |
| radarr       |        |   —    |        |          |    ✓    |  ✓  |  ✓   |     ✓     |          |          |                |
| lidarr       |        |        |   —    |          |    ✓    |  ✓  |  ✓   |     ✓     |          |          |                |
| prowlarr     |   ✓    |   ✓    |   ✓    |    —     |         |     |      |           |          |          |                |
| recyclarr    |   ✓    |   ✓    |        |          |         |     |      |           |          |          |                |
| bazarr       |   ✓    |   ✓    |        |          |         |     |      |           |          |          |                |
| jellyseerr   |   ✓    |   ✓    |        |          |         |     |      |           |    ✓     |          |                |
| nzbhydra2    |        |        |        |          |    ✓    |     |      |     —     |          |          |                |
| grafana      |        |        |        |          |         |     |      |           |          |    ✓     |                |
| portainer    |        |        |        |          |         |     |      |           |          |          |       ✓        |
| homarr       |   ✓    |   ✓    |   ✓    |    ✓     |    ✓    |  ✓  |  ✓   |           |    ✓     |          |                |
| organizr     |   ✓    |   ✓    |   ✓    |    ✓     |    ✓    |  ✓  |  ✓   |     ✓     |    ✓     |          |                |

---

## What "easier integration" actually unlocks

| Integration | Today | With collected keys |
|---|---|---|
| Prowlarr → arr indexer sync | Manually paste each arr's URL + API key into Prowlarr UI | One-shot script POSTs to `/api/v1/applications` with prefilled `${SONARR_API_KEY}` |
| Sonarr/Radarr → SABnzbd download client | Open each arr, add SABnzbd, paste key | Auto-create via `/api/v3/downloadclient` |
| Bazarr → Sonarr/Radarr | Configure URL + key per arr in Bazarr UI | Pre-populate `config.ini` |
| Tautulli → Plex | Manual token paste | Token captured during plex claim flow |
| Homarr/Homepage dashboards | Paste each key into YAML | Generate dashboard config from key store |
| ds-managed health checks | Per-app one-off scripts | `curl -H "X-Api-Key: ${SONARR_API_KEY}" ${arr}/api/v3/system/status` becomes uniform |

The Prowlarr→arr and arr→download-client cases alone save ~30 manual UI clicks per install. That's the headline value.

### Highest-leverage integrations

Ranked by manual-clicks-saved per fresh install:

1. **Prowlarr → arrs** — ~5 fields × N arrs (URL, API key, sync categories, tags, priority). Single most painful manual step in a typical setup.
2. **Arrs → SABnzbd/qBittorrent** — download client setup per arr (3 apps × 2 clients × ~6 fields).
3. **Recyclarr → arrs** — one YAML file but needs API keys for each arr; trivial to autogen.
4. **Bazarr → arrs** — 2 wiring steps.
5. **Homarr/Homepage** — N×M API keys pasted into one config file; high payoff because dashboards become "live" instead of static link lists.
6. **Jellyseerr → arrs + Jellyfin** — request flow, 4–5 fields.
7. **Portainer ↔ agents** — `AGENT_SECRET` must match on both sides; if generated centrally, deployment of new nodes becomes one-line.

---

## Suggested concrete shape

New files (following DockSTARTer's one-script-per-command pattern):

- `scripts/api_key_collect.sh` — defines `api_key_collect` + dispatcher to per-app collectors
- `scripts/api_key_collect_sonarr.sh`, `..._radarr.sh`, `..._sabnzbd.sh` etc. — one per app
- `scripts/api_key_store_into.sh` — writes to `api_keys.toml` (uses existing `config_toml_set`)
- `scripts/api_key_get_into.sh` — reads from `api_keys.toml`
- `scripts/api_keys_to_env.sh` — regenerates `.env.app.keys` from the toml store
- `scripts/integrate_prowlarr.sh`, `integrate_arr_download_clients.sh` — opinionated wiring that consumes the keys

Hook points:

- After `apply_config` / `ds -c up` finishes: optionally run `api_key_collect` then `api_keys_to_env` then `integrate_*` (gated behind a global like `GLOBAL_AUTO_INTEGRATE='true'`).
- Standalone: `ds --collect-keys`, `ds --integrate` for manual runs.

---

## Special cases worth flagging

- **qBittorrent has no API key.** It uses session-based auth with username+password. To automate, you log in (`POST /api/v2/auth/login`), get a `SID` cookie, then call endpoints. Either store the credentials (less ideal — visible in `docker inspect`) or set `WebUI\AuthSubnetWhitelist` to the docker network so other containers bypass auth entirely. The whitelist trick is what most arr setups end up using.
- **Jellyfin keys are DB-backed**, not file-readable. You must either run a SQL query against `jellyfin.db` (read-only, while the container is stopped or via WAL-safe access) or do the API exchange flow: `POST /Users/AuthenticateByName` with admin creds → token from response → `POST /Auth/Keys` to mint a long-lived API key.
- **Plex** uses tokens obtained via plex.tv claim flow. Different beast — needs the user's Plex account. Usually solved by extracting the `Plex-Token` from `Preferences.xml` after first run.
- **SABnzbd has two keys**: `api_key` and `nzb_key`. Arrs typically want `api_key`. Don't conflate them.
- **MariaDB password** is set at init time and *cannot* be changed via env afterwards — the password lives in the mysql.user table. Need to either fix it before first run or run `ALTER USER` once and store the chosen value.
- **InfluxDB v2 token** is set on first init via env. Re-creating a healthy v2 setup after losing the token is genuinely painful — collect it on first run.

---

## Risks

1. **Permissions**: configs are 0600 owned by PUID. Reading them under root via sudo works, but propagating into the store needs care to keep `0600 root:root` (or `PUID:PGID`).
2. **Key rotation**: if a user regenerates a key in the app UI, the store goes stale. The hybrid approach handles this on next collect, but anything that *cached* the old key (Prowlarr's view of Sonarr) needs re-syncing.
3. **State file in git**: `api_keys.toml` must be in `.gitignore` and never echoed to logs. Add a `redact_api_keys` filter to the existing logging layer.
4. **Backups**: this becomes the single most sensitive file in the install. Backup tooling needs to encrypt it or skip it explicitly.
5. **First-run chicken-and-egg**: for pre-seeding, you need to know what config schema each app accepts as minimal-valid. Versions drift. Approach A (scrape post-first-run) sidesteps this entirely — recommend defaulting to A and only pre-seeding for apps where it's been tested.

---

## Recommended collection priority

| Phase | Apps | Why |
|---|---|---|
| 1 (MVP) | sonarr, radarr, lidarr, prowlarr | Unlocks the prowlarr-push integration — biggest payoff |
| 2 | sabnzbd, jackett, nzbhydra2 | Unlocks download client + indexer wiring |
| 3 | qbittorrent (creds), jellyfin, portaineragent | More complex extraction but high value |
| 4 | grafana, influxdb, mariadb | DB/metrics layer — fewer users but they need it badly |
| 5 | organizr, flame, homarr/homepage | Dashboard consumers — depend on phases 1–3 being done |

Phase 1 alone covers ~60% of the "I wired this up by hand and it took an hour" pain.
