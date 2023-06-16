#!/bin/bash
sudo rm -Rf ./tmp/*
docker rmi $(docker images -qa -f 'dangling=true') 2> /dev/null
docker build -t nodejs .
docker run --rm -it \
-e AWS_REGION=$AWS_REGION \
-e AWS_ACCESS_KEY=$AWS_ACCESS_KEY \
-e AWS_SECRET_KEY=$AWS_SECRET_KEY \
--mount type=bind,source="$(pwd)"/tmp,target=/Release \
--entrypoint bash nodejs
