#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

integrate_bazarr() {
	# integrate_bazarr
	# Writes [sonarr] and [radarr] sections in Bazarr's config.ini so
	# Bazarr knows how to talk to each arr. Bazarr's config.ini is
	# section-aware so we use awk+inplace rather than config_ini_set.
	{
		printf '\n=== integrate_bazarr @ %s ===\n' "$(date -Iseconds)"
	} >> "${INTEGRATION_LOG_FILE}" 2>&1 || true

	local bazarr_enabled=""
	run_script 'env_get_into' bazarr_enabled "BAZARR__ENABLED" 2> /dev/null || true
	is_true "${bazarr_enabled}" || {
		notice "Bazarr is not enabled; skipping integrate_bazarr."
		return 0
	}

	local config="${DOCKER_VOLUME_CONFIG}/bazarr/config/config.ini"
	if [[ ! -f ${config} ]]; then
		notice "Bazarr config not present; skipping integrate_bazarr."
		return 0
	fi

	local sonarr_key radarr_key
	run_script 'api_key_get_into' sonarr_key "sonarr.api_key" 2> /dev/null || sonarr_key=""
	run_script 'api_key_get_into' radarr_key "radarr.api_key" 2> /dev/null || radarr_key=""

	if [[ -n ${sonarr_key} ]]; then
		_bazarr_write_section "${config}" "sonarr" "sonarr" 8989 "${sonarr_key}"
	fi
	if [[ -n ${radarr_key} ]]; then
		_bazarr_write_section "${config}" "radarr" "radarr" 7878 "${radarr_key}"
	fi
}

_bazarr_write_section() {
	local file=$1 section=$2 host=$3 port=$4 key=$5
	python3 - "$file" "$section" "$host" "$port" "$key" <<'PY' 2> /dev/null || _bazarr_write_section_awk "$@"
import sys
from configparser import ConfigParser

cp = ConfigParser()
cp.read(sys.argv[1])
sec = sys.argv[2]
if not cp.has_section(sec):
    cp.add_section(sec)
cp.set(sec, 'ip', sys.argv[3])
cp.set(sec, 'port', sys.argv[4])
cp.set(sec, 'apikey', sys.argv[5])
cp.set(sec, 'ssl', 'False')
with open(sys.argv[1], 'w') as f:
    cp.write(f)
PY
	notice "Wrote [${section}] section to Bazarr config."
}

_bazarr_write_section_awk() {
	# Pure-bash fallback if python3 is missing.
	local file=$1 section=$2 host=$3 port=$4 key=$5
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.bazarr.XXXXXXXXXX")
	awk -v s="${section}" -v h="${host}" -v p="${port}" -v k="${key}" '
		BEGIN { found = 0; cur = "" }
		/^\[.*\]/ {
			if (cur == s && !found) {
				print "ip = " h; print "port = " p; print "apikey = " k; print "ssl = False"; found = 1
			}
			cur = substr($0, 2, length($0)-2); print; next
		}
		cur == s && /^(ip|port|apikey|ssl)[[:space:]]*=/ { next }
		{ print }
		END {
			if (!found) {
				print ""; print "[" s "]"; print "ip = " h; print "port = " p; print "apikey = " k; print "ssl = False"
			}
		}
	' "${file}" > "${TempFile}" && mv "${TempFile}" "${file}"
}

test_integrate_bazarr() {
	warn "CI does not test integrate_bazarr (requires a running stack)."
}
