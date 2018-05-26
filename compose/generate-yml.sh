#!/bin/bash

echo "#!/bin/bash" > ./docker-compose.`hostname`.sh
echo "docker run --rm -v ${PWD}:/workdir mikefarah/yq yq m \\" >> ./docker-compose.`hostname`.sh
echo "./reqs/v1.yml \\" >> ./docker-compose.`hostname`.sh
echo "./reqs/v2.yml \\" >> ./docker-compose.`hostname`.sh
while read l || [ -n "$l" ]; do
  for f in ./apps/*.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\. ]]; then
      echo "$f \\" >> ./docker-compose.`hostname`.sh
    fi
  done
done <./`hostname`.conf
echo "> ./docker-compose.`hostname`.yml" >> ./docker-compose.`hostname`.sh
echo "docker-compose -f ./docker-compose.`hostname`.yml up -d" >> ./docker-compose.`hostname`.sh

bash ./docker-compose.`hostname`.sh
rm ./docker-compose.`hostname`.sh
