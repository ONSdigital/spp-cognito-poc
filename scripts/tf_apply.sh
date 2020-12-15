#!/bin/bash

set -euo pipefail

pushd poc_client
  DOCKER_BUILDKIT=1 docker build --ssh default . -t sambryant/spp-poc-client:redis
  docker push sambryant/spp-poc-client:redis
popd

pushd fake_baw
  docker build . -t sambryant/spp-fake-baw
  docker push sambryant/spp-fake-baw
popd


terraform apply --auto-approve terraform
