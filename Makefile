mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: show-help
## This help screen
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)";echo;sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|LC_ALL='C' sort -f|awk -F --- -v n=$$(tput cols) -v i=29 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'

.PHONY: format
## Format python
format:
	@cd poc_client && poetry run black .
	@cd poc_client && poetry run isort .
	@terraform fmt terraform

.PHONY: lint
## Run styling checks for python
lint:
	@cd poc_client && poetry run black --check .
	@cd poc_client && poetry run isort --check .
	@terraform fmt --check terraform

.PHONY: tf-apply
## Run terraform apply
tf-apply:
	@./scripts/tf_apply.sh

.PHONY: run-poc-client
## Run poc client flask app
run-poc-client:
	@./scripts/start_poc_client.sh

.PHONY: run-fake-baw
## Run fake baw flask app
run-fake-baw:
	@./scripts/start_fake_baw.sh
