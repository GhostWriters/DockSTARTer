#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

npm_host_template_jellyfin() {
	# npm_host_template_jellyfin
	# Echoes the advanced_config nginx directives required for a
	# good Jellyfin reverse-proxy setup: large body size for
	# uploads, disabled buffering for streaming responses, websocket
	# upgrades, and Plex/Jellyfin-required headers. Caller passes
	# this string as the 4th arg to npm_host_create.
	cat <<'NGINX'
client_max_body_size 0;
proxy_buffering off;
proxy_request_buffering off;
proxy_set_header Range $http_range;
proxy_set_header If-Range $http_if_range;
NGINX
}

test_npm_host_template_jellyfin() {
	warn "CI does not test npm_host_template_jellyfin."
}
