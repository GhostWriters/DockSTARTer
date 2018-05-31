#!/bin/bash

ARCH=""
case $(uname -m) in
  i386)   ARCH="386" ;;
  i686)   ARCH="386" ;;
  x86_64) ARCH="amd64" ;;
  arm)    dpkg --print-architecture | grep -q "arm64" && ARCH="arm64" || ARCH="arm" ;;
esac

RUNFILE="./docker-compose.`hostname`.sh"
echo "#!/bin/bash" > $RUNFILE
echo "rm -rf ./`hostname`/" >> $RUNFILE
echo "mkdir -p ./`hostname`/" >> $RUNFILE
echo "cp .env ./`hostname`/" >> $RUNFILE
echo "docker run --rm -v ${PWD}:/workdir mikefarah/yq yq m \\" >> $RUNFILE
echo "./.reqs/v1.yml \\" >> $RUNFILE
echo "./.reqs/v2.yml \\" >> $RUNFILE
while read l || [ -n "$l" ]; do
  for f in ./.apps/*.override.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\.override\. ]]; then
      echo "$f \\" >> $RUNFILE
    fi
  done
  for f in ./.apps/*.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\. ]]; then
      if [[ $ARCH == "arm64" ]]; then
        if [[ -f ${f/\.apps\//.apps\/aarch64\/} ]]; then
          echo "${f/\.apps\//.apps\/aarch64\/} \\" >> $RUNFILE
        fi
        if [[ -f ${f/\.apps\//.apps\/armhf\/} ]]; then
          echo "${f/\.apps\//.apps\/armhf\/} \\" >> $RUNFILE
        fi
        if [[ -f ${f/\.apps\//.apps\/aarch64\/} ]] || [[ -f ${f/\.apps\//.apps\/armhf\/} ]]; then
          echo "$f \\" >> $RUNFILE
        fi
      fi
      if [[ $ARCH == "arm" ]]; then
        if [[ -f ${f/\.apps\//.apps\/armhf\/} ]]; then
          echo "${f/\.apps\//.apps\/armhf\/} \\" >> $RUNFILE
          echo "$f \\" >> $RUNFILE
        fi
      fi
      if [[ $ARCH == "amd64" ]]; then
        echo "$f \\" >> $RUNFILE
      fi
    fi
  done
done <"./`hostname`.conf"
echo "> ./`hostname`/docker-compose.yml" >> $RUNFILE
echo "cd ./`hostname`/ || exit" >> $RUNFILE
echo "docker-compose up -d" >> $RUNFILE

bash $RUNFILE
rm $RUNFILE
