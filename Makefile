# Make defaults
.ONESHELL:
.DEFAULT_GOAL := help

submodule-init: ## submodule-init
submodule-init:
	git submodule update --init --recursive
	git submodule update --remote --recursive

destroy: ## destroy
destroy:
	set -e
	terraform destroy -auto-approve -target 'module.unrestricted-argocd' -target 'module.restricted-argocd'
	terraform destroy -auto-approve -target 'module.unrestricted-kubernetes'
	terraform destroy -auto-approve -target 'module.restricted-kubernetes'
	terraform destroy -auto-approve -target 'module.unrestricted-gitlab-variables' -target 'module.restricted-gitlab-variables'
	terraform destroy -auto-approve -target 'module.unrestricted-project-factory' -target 'module.restricted-project-factory'
	terraform destroy -auto-approve -target 'module.gitlab'

create: ## create:
create:
	set -e
	terraform apply -auto-approve -target 'module.gitlab' -target 'module.unrestricted-project-factory' -target 'module.restricted-project-factory'
	terraform apply -auto-approve -target 'module.unrestricted-gitlab-variables' -target 'module.restricted-gitlab-variables'
	terraform apply -auto-approve -target 'module.unrestricted-kubernetes' -target 'module.restricted-kubernetes'
	terraform apply -auto-approve -target 'module.unrestricted-argocd' -target 'module.restricted-argocd'
	terraform apply -auto-approve

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'
