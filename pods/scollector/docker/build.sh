#!/bin/bash
#docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --push -t sylvaintremblay/scollector-multiarch .
docker buildx build --platform linux/amd64,linux/arm/v7 --push -t sylvaintremblay/scollector-multiarch .
