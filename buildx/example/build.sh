#!/bin/bash

#docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --push -t registry:5000/ex .
#docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --push -t localhost:5000/ex .
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --push -t sylvaintremblay/buildx-test .

echo "------------"

docker buildx imagetools inspect sylvaintremblay/buildx-test


echo "-----" try it :

echo "try it: docker run sylvaintremblay/buildx-test"
