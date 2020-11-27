#!/bin/bash

set -euo pipefail

pushd fake_baw
  FLASK_APP=application.py \
  poetry run python -m flask run
popd
