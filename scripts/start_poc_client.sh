#!/bin/bash

set -euo pipefail

pushd terraform
  rm -rf .terraform
  ln -s ../.terraform .terraform

  client_id="$(terraform output client_id)"
  client_secret="$(terraform output client_secret)"
  cognito_domain="$(terraform output cognito_domain)"
  cognito_endpoint="$(terraform output cognito_endpoint)"
popd

pushd poc_client
  FLASK_APP=application.py \
  CLIENT_ID="${client_id}" \
  CLIENT_SECRET="${client_secret}" \
  COGNITO_DOMAIN="${cognito_domain}" \
  COGNITO_ENDPOINT="${cognito_endpoint}" \
  CALLBACK_URL="http://localhost:5000/auth/callback" \
  poetry run python -m flask run
popd
