#!/bin/bash

ARCH=""
case $(uname -m) in
  x86_64) ARCH="amd64" ;;
  arm)    dpkg --print-architecture | grep -q "arm64" && ARCH="arm64" || ARCH="arm" ;;
esac

RUNFILE="./docker-compose.${HOSTNAME}.sh"
echo "#!/bin/bash" > ${RUNFILE}
echo "rm -rf ./${HOSTNAME}/" >> ${RUNFILE}
echo "mkdir -p ./${HOSTNAME}/" >> ${RUNFILE}
echo "cp .env ./${HOSTNAME}/" >> ${RUNFILE}
# # Begin temp fix
#echo "docker run --rm -v ${PWD}:/workdir mikefarah/yq yq m \\" >> ${RUNFILE}
if [[ ${ARCH} == "arm64" ]]; then
  sudo curl -L "https://github.com/mikefarah/yq/releases/download/1.15.0/yq_linux_arm" -o /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
fi
if [[ ${ARCH} == "arm" ]]; then
  sudo curl -L "https://github.com/mikefarah/yq/releases/download/1.15.0/yq_linux_arm" -o /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
fi
if [[ ${ARCH} == "amd64" ]]; then
  sudo curl -L "https://github.com/mikefarah/yq/releases/download/1.15.0/yq_linux_amd64" -o /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
fi
echo "yq m \\" >> ${RUNFILE}
# # End temp fix
echo "./.reqs/v1.yml \\" >> ${RUNFILE}
echo "./.reqs/v2.yml \\" >> ${RUNFILE}
while read l || [ -n "${l}" ]; do
  for f in ./.apps/*.override.yml
  do
    [[ -e ${f} ]] || break
    if [[ ${f} =~ \/${l}\.override\. ]]; then
      echo "${f} \\" >> ${RUNFILE}
    fi
  done
  for f in ./.apps/*.yml
  do
    [[ -e ${f} ]] || break
    if [[ ${f} =~ \/${l}\. ]]; then
      if [[ ${ARCH} == "arm64" ]]; then
        if [[ -f ${f/\.apps\//.apps\/aarch64\/} ]]; then
          echo "${f/\.apps\//.apps\/aarch64\/} \\" >> ${RUNFILE}
          echo "${f} \\" >> ${RUNFILE}
        fi
        if [[ -f ${f/\.apps\//.apps\/armhf\/} ]]; then
          echo "${f/\.apps\//.apps\/armhf\/} \\" >> ${RUNFILE}
          echo "${f} \\" >> ${RUNFILE}
        fi
      fi
      if [[ ${ARCH} == "arm" ]]; then
        if [[ -f ${f/\.apps\//.apps\/armhf\/} ]]; then
          echo "${f/\.apps\//.apps\/armhf\/} \\" >> ${RUNFILE}
          echo "${f} \\" >> ${RUNFILE}
        fi
      fi
      if [[ ${ARCH} == "amd64" ]]; then
        echo "${f} \\" >> ${RUNFILE}
      fi
    fi
  done
done <"./${HOSTNAME}.conf"
echo "> ./${HOSTNAME}/docker-compose.yml" >> ${RUNFILE}
echo "cd ./${HOSTNAME}/ || exit" >> ${RUNFILE}
echo "docker-compose up -d" >> ${RUNFILE}

bash ${RUNFILE}
rm ${RUNFILE}
