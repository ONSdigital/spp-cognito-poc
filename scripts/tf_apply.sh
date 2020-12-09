#!/bin/bash

set -euo pipefail

pushd poc_client
  DOCKER_BUILDKIT=1 docker build --ssh default . -t sambryant/spp-poc-client
  docker push sambryant/spp-poc-client
popd

pushd fake_baw
  docker build . -t sambryant/spp-fake-baw
  docker push sambryant/spp-fake-baw
popd


terraform apply --auto-approve terraform
