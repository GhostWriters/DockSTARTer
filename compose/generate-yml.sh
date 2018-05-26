#!/bin/bash

echo "#!/bin/bash" > ./generate-yml.`hostname`.sh
echo "docker run --rm -v ${PWD}:/workdir mikefarah/yq yq m \\" >> ./generate-yml.`hostname`.sh
echo "./reqs/v1.yml \\" >> ./generate-yml.`hostname`.sh
echo "./reqs/v2.yml \\" >> ./generate-yml.`hostname`.sh
while read l || [ -n "$l" ]; do
  for f in ./apps/*.yml
  do
    [[ -e $f ]] || break
    if [[ $f =~ \/$l\. ]]; then
      echo "$f \\" >> ./generate-yml.`hostname`.sh
    fi
  done
done <./`hostname`.conf
echo "> ./generate-yml.`hostname`.yml" >> ./generate-yml.`hostname`.sh
echo "docker-compose -f ./generate-yml.`hostname`.yml up -d" >> ./generate-yml.`hostname`.sh

bash ./generate-yml.`hostname`.sh
rm ./generate-yml.`hostname`.sh
