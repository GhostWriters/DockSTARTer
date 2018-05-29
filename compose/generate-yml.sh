#!/bin/bash

RUNFILE="./docker-compose.`hostname`.sh"
echo "#!/bin/bash" > $RUNFILE
echo "mkdir -p ./`hostname`/" >> $RUNFILE
echo "cp .env ./`hostname`/" >> $RUNFILE
echo "docker run --rm -v ${PWD}:/workdir mikefarah/yq yq m \\" >> $RUNFILE
echo "./reqs/v1.yml \\" >> $RUNFILE
echo "./reqs/v2.yml \\" >> $RUNFILE
while read l || [ -n "$l" ]; do
  for f in ./apps/*.override.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\.override\. ]]; then
      echo "$f \\" >> $RUNFILE
    fi
  done
  for f in ./apps/*.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\. ]]; then
      echo "$f \\" >> $RUNFILE
    fi
  done
done <"./`hostname`.conf"
echo "> ./`hostname`/docker-compose.yml" >> $RUNFILE
echo "cd ./`hostname`/ || exit" >> $RUNFILE
echo "docker-compose up -d" >> $RUNFILE

bash $RUNFILE
rm $RUNFILE
