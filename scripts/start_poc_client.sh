#!/bin/bash

set -euo pipefail

pushd terraform
  rm -rf .terraform
  ln -s ../.terraform .terraform

  client_id="$(terraform output client_id)"
  client_secret="$(terraform output client_secret)"
  cognito_domain="$(terraform output cognito_domain)"
  cognito_public_key_url="$(terraform output cognito_public_key_url)"
popd

pushd poc_client
  FLASK_APP=application.py \
  CLIENT_ID="${client_id}" \
  CLIENT_SECRET="${client_secret}" \
  COGNITO_DOMAIN="${cognito_domain}" \
  COGNITO_PUBLIC_KEY_URL="${cognito_public_key_url}" \
  APP_HOST="http://localhost:5000" \
  poetry run python -m flask run
popd
