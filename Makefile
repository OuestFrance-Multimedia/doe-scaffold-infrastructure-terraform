include .env
export

# Make defaults
.ONESHELL:
.DEFAULT_GOAL := help
.SILENT: init

# Make variables
SHELL := /bin/bash
ENVFILE := .env

submodule-init: ## submodule-init
submodule-init:
	git submodule update --init --recursive
	git submodule update --remote --recursive
	cd modules/additi-kubernetes; \
		echo "input path to git-crypt unlock key file for kubernetes module (see Keepass: gitlab/tfmodules/additi-kubernetes-gitcrypt): "; \
		read UNLOCK_FILE; \
		git-crypt unlock $${UNLOCK_FILE}


init: ## init
init:
	set -e
	terraform get
	terraform init
	terraform validate
	set +e
	source .env
	gcloud container clusters get-credentials $$UNRESTRICTED_CLUSTER_NAME 	--project=$$UNRESTRICTED_GCP_PROJECT_ID --region $$UNRESTRICTED_CLUSTER_LOCATION
	gcloud container clusters get-credentials $$RESTRICTED_CLUSTER_NAME 	--project=$$RESTRICTED_GCP_PROJECT_ID 	--region $$RESTRICTED_CLUSTER_LOCATION
	exit 0

create: ## create
create:
	init
	set -e
	terraform apply -target 'module.gitlab'
	create-unrestricted
	create-restricted
	terraform apply

create-unrestricted: ## create-unrestricted
create-unrestricted:
	set -e
	terraform apply -target 'module.unrestricted-project-factory'
	terraform apply -target 'module.unrestricted-gitlab-variables'
	terraform apply -target 'module.unrestricted-kubernetes'
	terraform apply -target 'module.unrestricted-loki'
	terraform apply -target 'module.unrestricted-promtail'
	terraform apply -target 'module.unrestricted-kube-prometheus-stack-with-grafana-install'
	terraform apply -target 'module.unrestricted-grafana'
	terraform apply -target 'module.unrestricted-argocd-install'
	terraform apply -target 'module.unrestricted-argocd-config'

show-unrestricted-creds: ## show-unrestricted-creds
show-unrestricted-creds:
	echo "grafana :"
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.unrestricted-project-factory.google_compute_address.grafana[0]") | .values.address'
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.unrestricted-kube-prometheus-stack-with-grafana-install.random_password.grafana_admin_password") | .values.result'
	echo "argocd :"
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.unrestricted-project-factory.google_compute_address.argocd[0]") | .values.address'
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.unrestricted-argocd-install.random_password.argocd_admin_password") | .values.result'

create-restricted: ## create-restricted
create-restricted:
	terraform apply -target 'module.restricted-project-factory'
	terraform apply -target 'module.restricted-gitlab-variables'
	terraform apply -target 'module.restricted-kubernetes'
	terraform apply -target 'module.restricted-loki'
	terraform apply -target 'module.restricted-promtail'
	terraform apply -target 'module.restricted-kube-prometheus-stack-with-grafana-install'
	terraform apply -target 'module.restricted-grafana'
	terraform apply -target 'module.restricted-argocd-install'
	terraform apply -target 'module.restricted-argocd-config'

show-restricted-creds: ## show-restricted-creds
show-restricted-creds:
	echo "grafana :"
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.restricted-project-factory.google_compute_address.grafana[0]") | .values.address'
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.restricted-kube-prometheus-stack-with-grafana-install.random_password.grafana_admin_password") | .values.result'
	echo "argocd :"
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.restricted-project-factory.google_compute_address.argocd[0]") | .values.address'
	terraform show -json|jq '.values.root_module.child_modules[].resources[] | select(.address == "module.restricted-argocd-install.random_password.argocd_admin_password") | .values.result'

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

