#!/bin/bash

TESTPATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"

cp "${TESTPATH}/compose/.env.example" "${TESTPATH}/compose/.env"
sed -i "s/_ENABLED=false/_ENABLED=true/" "${TESTPATH}/compose/.env"
#sed -i "s/EMBY_ENABLED=true/EMBY_ENABLED=false/" "${TESTPATH}/compose/.env"
sed -i "s/^\s*devices\:$//" "${TESTPATH}/compose/.apps/emby/emby.yml"
sed -i "s/^.*renderD128.*$//" "${TESTPATH}/compose/.apps/emby/emby.yml"
sed -i "s/HEADPHONES_PORT_8181=8181/HEADPHONES_PORT_8181=18181/" "${TESTPATH}/compose/.env"
sed -i "s/PLEX_PORT_1900=1900/PLEX_PORT_1900=11900/" "${TESTPATH}/compose/.env"
sed -i "s/PLEXREQUESTS_PORT_3000=3000/PLEXREQUESTS_PORT_3000=13000/" "${TESTPATH}/compose/.env"
sed -i "s/RUTORRENT_PORT_51413=51413/RUTORRENT_PORT_51413=41413/" "${TESTPATH}/compose/.env"
sed -i "s/RUTORRENT_PORT_6881=6881/RUTORRENT_PORT_6881=16881/" "${TESTPATH}/compose/.env"
sed -i "s/SABNZBDVPN_PORT_8080=8080/SABNZBDVPN_PORT_8080=28080/" "${TESTPATH}/compose/.env""${TESTPATH}/compose/.env"
sed -i "s/TRANSMISSIONVPN_PORT_9091=9091/TRANSMISSIONVPN_PORT_9091=19091/" "${TESTPATH}/compose/.env"
sed -i "s/UNIFI_PORT_6789=6789/UNIFI_PORT_6789=16789/" "${TESTPATH}/compose/.env"
sed -i "s/UNIFI_PORT_7878=7878/UNIFI_PORT_7878=17878/" "${TESTPATH}/compose/.env"
sed -i "s/UNIFI_PORT_8080=8080/UNIFI_PORT_8080=18080/" "${TESTPATH}/compose/.env"
sed -i "s/UNIFI_PORT_8081=8081/UNIFI_PORT_8081=18081/" "${TESTPATH}/compose/.env"
bash "${TESTPATH}/generate-yml.sh"
echo
cat "${TESTPATH}/compose/docker-compose.yml" || exit 1
echo
cd "${TESTPATH}/compose/" || exit 1;
docker-compose up -d || exit 1;
cd "${TESTPATH}" || exit 1;
