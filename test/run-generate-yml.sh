#!/bin/bash
# Script Name: Generate YML run

SCRIPTPATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd "$SCRIPTPATH/compose/" || exit 1
cp .env.example .env
sed -i "s/_ENABLED=false/_ENABLED=true/" .env
#sed -i "s/EMBY_ENABLED=true/EMBY_ENABLED=false/" .env
sed -i "s/^.*renderD128.*$//" .apps/emby/emby.yml
sed -i "s/HEADPHONES_PORT_8181=8181/HEADPHONES_PORT_8181=18181/" .env
sed -i "s/PLEX_PORT_1900=1900/PLEX_PORT_1900=11900/" .env
sed -i "s/RUTORRENT_PORT_51413=51413/RUTORRENT_PORT_51413=41413/" .env
sed -i "s/RUTORRENT_PORT_6881=6881/RUTORRENT_PORT_6881=16881/" .env
sed -i "s/UNIFI_PORT_6789=6789/UNIFI_PORT_6789=16789/" .env
sed -i "s/UNIFI_PORT_7878=7878/UNIFI_PORT_7878=17878/" .env
sed -i "s/UNIFI_PORT_8080=8080/UNIFI_PORT_8080=18080/" .env
sed -i "s/UNIFI_PORT_8081=8081/UNIFI_PORT_8081=18081/" .env
bash generate-yml.sh
echo "###"
cat docker-compose.yml || exit 1
echo "###"
docker-compose up -d || exit 1
