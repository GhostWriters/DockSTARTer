# NPM Auto-Integration Investigation

How realistic is "deploy DockSTARTer + Nginx Proxy Manager → every enabled app instantly reachable at `<app>.domain.com` with sensible TLS, websockets, and proxy headers, zero clicks"?

**Short answer**: highly feasible. NPM has a complete REST API and DockSTARTer already knows every app's container name + port. The work is moderate — ~1 script per app for the few that need quirks, plus one generic templater for the rest.

---

## NPM's automation surface

NPM exposes `/api/*` (the same API the UI uses). Auth flow:

```bash
# Get JWT
curl -X POST http://npm:81/api/tokens \
  -H "Content-Type: application/json" \
  -d '{"identity":"admin@example.com","secret":"changeme"}'
# → {"token":"eyJhbGciOi...","expires":"2026-05-27T..."}

# Create proxy host
curl -X POST http://npm:81/api/nginx/proxy-hosts \
  -H "Authorization: Bearer ${JWT}" \
  -H "Content-Type: application/json" \
  -d @sonarr-host.json
```

Key endpoints DockSTARTer would need:

| Endpoint | Purpose |
|---|---|
| `POST /api/tokens` | Auth (returns JWT, 24h validity) |
| `PUT /api/users/1/auth` | Change default admin password (mandatory after first run) |
| `GET/POST /api/nginx/proxy-hosts` | The actual reverse-proxy entries |
| `GET/POST /api/nginx/certificates` | Let's Encrypt cert creation |
| `GET/POST /api/nginx/access-lists` | IP whitelists / basic auth for sensitive apps |

---

## NPM bootstrap (the awkward first step)

NPM ships with hardcoded defaults `admin@example.com` / `changeme` that **must be changed via API on first use** — UI forces it but API doesn't. So `ds --integrate-npm` flow:

1. Check if `${CONFIG}/npm/data/database.sqlite` exists → first run if not
2. POST `/api/tokens` with default creds
3. PUT new admin email + generated password via `/api/users/1` and `/api/users/1/auth`
4. Store the new password in `api_keys.toml` (NPM joins the collect-keys system)
5. From now on use the rotated creds

This is the one piece that doesn't fit the "scrape after first run" pattern from the previous design — NPM is more like Approach C (pre-seed credentials at bootstrap).

---

## Per-app proxy host template

Generic baseline that works for most apps:

```json
{
  "domain_names": ["sonarr.example.com"],
  "forward_scheme": "http",
  "forward_host": "sonarr",
  "forward_port": 8989,
  "access_list_id": 0,
  "certificate_id": "new",
  "meta": { "letsencrypt_email": "you@example.com", "letsencrypt_agree": true, "dns_challenge": false },
  "advanced_config": "",
  "locations": [],
  "block_exploits": true,
  "caching_enabled": false,
  "allow_websocket_upgrade": true,
  "http2_support": true,
  "hsts_enabled": true,
  "hsts_subdomains": false,
  "ssl_forced": true
}
```

`forward_host` = container name (docker compose's internal DNS resolves it). `forward_port` = the **container** port, not the host port — NPM and the target share a docker network so host port-mapping is irrelevant.

---

## Per-app requirements (from the integration matrix)

| App | Port | WS | Quirks |
|---|---|---|---|
| **sonarr** | 8989 | ✓ | SignalR needs `allow_websocket_upgrade=true`. Supports `<UrlBase>` for subpath routing |
| **radarr** | 7878 | ✓ | Same as sonarr |
| **lidarr** | 8686 | ✓ | Same |
| **readarr** | 8787 | ✓ | Same |
| **prowlarr** | 9696 | ✓ | Same — SignalR for live notifications |
| **bazarr** | 6767 | ✓ | WS for log streaming |
| **jackett** | 9117 | — | Plain HTTP. Behind reverse proxy needs `Jackett ProxyBaseURL` set |
| **sabnzbd** | 8080 | — | Refuses requests unless `host_whitelist` in `sabnzbd.ini` includes the public hostname. **Must edit config or NPM will get HTTP 403.** |
| **nzbhydra2** | 5076 | ✓ | Set `urlBase` in `nzbhydra.yml` if using subpath |
| **qbittorrent** | 8080 | — | Needs `WebUI\HostHeaderValidation=false` and `WebUI\CSRFProtection=false` (or set domain in `WebUI\TrustedReverseProxies`). Otherwise: HTTP 401 / "unauthorized origin" |
| **transmission** | 9091 | — | `rpc-host-whitelist` and `rpc-whitelist` need entries for NPM container IP or the public hostname |
| **deluge** | 8112 | ✓ | Plain HTTP; works with generic template |
| **jellyfin** | 8096 | ✓ | **Custom advanced_config required** — large `client_max_body_size`, disabled buffering for streaming, WebSocket for live remote control |
| **plex** | 32400 | ✓ | Needs `proxy_buffering off` and `Plex-*` header preservation. Generally not proxied — Plex prefers direct connections via plex.tv claim |
| **overseerr / jellyseerr** | 5055 | ✓ | Generic works; ensure `trust proxy` is set in app |
| **tautulli** | 8181 | ✓ | Set `HTTP Root` in tautulli for subpath |
| **portainer** | 9000 | ✓ | WS for terminal/console |
| **homarr / homepage** | 7575 / 3000 | — | Generic works |
| **organizr** | 80 | — | Generic works |
| **flame** | 5005 | — | Generic works |
| **grafana** | 3000 | ✓ | Set `GF_SERVER_ROOT_URL` env to public URL or auth callbacks break |
| **influxdb** | 8086 | — | Generic works |
| **gluetun** | n/a | — | Don't proxy — control server should never be public |
| **flaresolverr** | 8191 | — | Internal-only service, no need to proxy |
| **xteve** | 34400 | — | Generic works |
| **speedtest** | 8765 | — | Generic works |
| **openspeedtest** | 3000 | — | Generic works |

### Apps that need config changes alongside the NPM entry

| App | What to change | Where |
|---|---|---|
| **sabnzbd** | Add `host_whitelist = sabnzbd.example.com` | `${CONFIG}/sabnzbd/sabnzbd.ini` `[misc]` section |
| **qbittorrent** | `WebUI\HostHeaderValidation=false` (or trusted proxy) | `${CONFIG}/qbittorrent/qBittorrent/config/qBittorrent.conf` |
| **transmission** | `rpc-host-whitelist`, `rpc-whitelist-enabled` | `${CONFIG}/transmission/settings.json` |
| **jellyfin** | `KnownProxies` in `network.xml`, `BaseUrl` if subpath | `${CONFIG}/jellyfin/config/network.xml` |
| **grafana** | `GF_SERVER_ROOT_URL` env in compose | `compose/.env.app.grafana` |

DockSTARTer's existing edit primitives (`env_set`, `config_ini_set`, `config_toml_set`) cover INI and env. Need new helpers for the XML cases (jellyfin's `network.xml`, the arr config files).

---

## What "automatic" looks like end-to-end

```bash
ds --integrate-npm --domain=example.com [--email=you@example.com]
```

Pipeline:

1. **Discover** — enumerate `<APP>__ENABLED='true'` apps from `${COMPOSE_ENV}`.
2. **Filter** — exclude apps in the "don't proxy" set (gluetun, flaresolverr).
3. **Bootstrap NPM** — rotate default creds if needed, store new admin pw in `api_keys.toml`.
4. **Per-app config fixes** — apply the host_whitelist / HostHeaderValidation / KnownProxies edits *before* NPM hits them.
5. **Cert strategy** — either:
   - Wildcard via DNS-01 (one cert for `*.example.com`) — needs `GLOBAL_CERT_DNS_PROVIDER` and an API token; most efficient.
   - Per-host HTTP-01 — simpler but requires port 80 reachable from the internet.
6. **Generate proxy hosts** — for each app: pick the template (generic or app-specific), POST to `/api/nginx/proxy-hosts`, request cert.
7. **Verify** — `curl -sI https://<app>.example.com` for each, log failures.
8. **Store** — write the NPM host IDs back to `api_keys.toml` so reruns are idempotent (update instead of recreate).

---

## Effort estimate

| Component | Difficulty | LOC estimate |
|---|---|---|
| NPM bootstrap (rotate creds, get JWT) | Easy | ~80 |
| Generic proxy-host template emitter | Easy | ~120 |
| Per-app override registry (port, ws, advanced_config) | Easy | ~200 (data, not logic) |
| sabnzbd / qbittorrent / transmission config edits | Medium (need shellcheck-clean INI/JSON edits) | ~150 each |
| jellyfin `network.xml` edit | Medium (XML) | ~150 |
| Cert request flow (wildcard or per-host) | Medium | ~200 |
| Idempotency / update-existing-host logic | Medium | ~150 |
| Verification + rollback on failure | Medium | ~150 |
| **Total** | | **~1500 LOC** across ~25 scripts |

That fits DockSTARTer's existing one-script-per-command structure cleanly. Naming pattern:

- `scripts/npm_token_get_into.sh` — bootstrap + JWT acquisition
- `scripts/npm_host_create.sh` — generic proxy-host POST
- `scripts/npm_host_template_<app>.sh` — only for the apps needing overrides (~6 files)
- `scripts/npm_app_prepare_<app>.sh` — pre-proxy config edits (sabnzbd, qbit, transmission, jellyfin, grafana)
- `scripts/npm_cert_request.sh` — LE request wrapper
- `scripts/integrate_npm.sh` — top-level orchestrator

---

## Risks / friction points

1. **NPM default-creds rotation has no rollback.** If the bootstrap fails mid-way (new pw set but not stored), the user is locked out. Fix: store the generated password *before* setting it. Also: provide `ds --reset-npm-password` that resets `database.sqlite` row 1 to the default.
2. **Let's Encrypt rate limits.** 50 certs per registered domain per week. A user with 20 enabled apps + redeploys = easy to hit. Strongly prefer the wildcard/DNS-01 path; document the limit.
3. **DNS readiness.** Per-host HTTP-01 requires `<app>.example.com` to resolve to the host's public IP before NPM requests the cert. Either skip cert request when DNS isn't ready, or default to wildcard.
4. **Container DNS dependency.** `forward_host: sonarr` only works because NPM and Sonarr share a docker network. Need to ensure all proxied apps join the same network as NPM — recommend a fixed `proxy` network (ties back to the `GLOBAL_PROXY_NETWORK` brainstormed earlier).
5. **App auth bypass.** If LAN-only apps (sabnzbd, qbittorrent) get a public NPM host, they're exposed. Either gate behind NPM access-lists (basic auth) by default, or refuse to proxy any app whose own auth is disabled. Recommend: opt-in flag `<APP>__NPM_EXPOSE='true'` rather than auto-publishing everything.
6. **WebSocket detection.** Hardcoded per-app in the override table — fine, but adding new apps requires updating that table. Could derive heuristically (apps with SignalR / known WS libraries) but explicit table is safer.
7. **Re-runs must be idempotent.** If host already exists, PUT not POST. Track NPM host IDs in `api_keys.toml` per app. If user deleted the host in UI, regenerate.

---

## Verdict

**This is one of the cleanest auto-integrations in the entire matrix** — NPM's API is well-documented, every app's port is already known, and DockSTARTer's existing config-edit primitives cover most of the per-app fixes. The main complication isn't NPM itself — it's the handful of apps that refuse traffic from a hostname they don't recognise (sabnzbd, qbit, transmission, jellyfin). Once those edits are wrapped in helper scripts, adding a new app to NPM becomes a 5-line override entry.

Best paired with the API key collection design from `api_integrations.md` — both share the `api_keys.toml` store and the same `ds --integrate` umbrella command.
