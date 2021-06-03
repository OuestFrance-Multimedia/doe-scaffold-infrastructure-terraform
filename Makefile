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

init: ## init
init:
	set -e
	terraform get
	terraform init
	terraform validate
	set +e
	source .env
	gcloud container clusters get-credentials $$UNRESTRICTED_CLUSTER_NAME 	--project=$$UNRESTRICTED_GCP_PROJECT_ID --region $$UNRESTRICTED_CLUSTER_LOCATION
	gcloud container clusters get-credentials $$RESTRICTED_CLUSTER_NAME 		--project=$$RESTRICTED_GCP_PROJECT_ID 	--region $$RESTRICTED_CLUSTER_LOCATION

# terraform destroy -target 'module.restricted-argocd-config'
# terraform destroy -target 'module.restricted-argocd-install'
# terraform destroy -target 'module.restricted-grafana'
# terraform destroy -target 'module.restricted-kube-prometheus-stack-with-grafana-install'
# terraform destroy -target 'module.restricted-kubernetes'

destroy: ## destroy
destroy:
	set -e
#	terraform destroy -auto-approve -target 'module.unrestricted-grafana'
#	terraform destroy -auto-approve	-target 'module.restricted-grafana'
	terraform destroy -auto-approve -target 'module.unrestricted-argocd-config' -target 'module.restricted-argocd-config'
	terraform destroy -auto-approve -target 'module.unrestricted-kubernetes' -target 'module.restricted-kubernetes'
	terraform destroy -auto-approve -target 'module.unrestricted-gitlab-variables' -target 'module.restricted-gitlab-variables'
	terraform destroy -auto-approve -target 'module.unrestricted-project-factory' -target 'module.restricted-project-factory'

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

create-unrestricted-auto-approve: ## create-unrestricted-auto-approve
create-unrestricted-auto-approve:
	set -e
	terraform apply -auto-approve -target 'module.unrestricted-project-factory'
	terraform apply -auto-approve -target 'module.unrestricted-gitlab-variables'
	terraform apply -auto-approve -target 'module.unrestricted-kubernetes'
	terraform apply -auto-approve -target 'module.unrestricted-kube-prometheus-stack-with-grafana-install'
	make port-forward-up-unrestricted && terraform apply -auto-approve -target 'module.unrestricted-grafana'
	terraform apply -auto-approve -target 'module.unrestricted-argocd-install'
	terraform apply -auto-approve -target 'module.unrestricted-argocd-config'

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

port-forward-up-unrestricted: ## port-forward-up-unrestricted
port-forward-up-unrestricted:
	source .env
	nohup kubectl port-forward svc/kube-prometheus-stack-grafana 2001:80 -n monitoring --context=$$UNRESTRICTED_CLUSTER_CONTEXT &>/dev/null &

port-forward-up-restricted: ## port-forward-up-unrestricted
port-forward-up-restricted:
	source .env
	nohup kubectl port-forward svc/kube-prometheus-stack-grafana 2101:80 -n monitoring --context=$$RESTRICTED_CLUSTER_CONTEXT 	&>/dev/null &

port-forward-up: ## port-forward-up
port-forward-up:
	make port-forward-up-unrestricted
	make port-forward-up-restricted
	sleep 2
	firefox http://127.0.0.1:2001
	firefox -private-window && sleep 1 && firefox -private-window http://127.0.0.1:2101

port-forward-down: ## port-forward-down
port-forward-down:
	set +e
	pkill -f "^kubectl port-forward svc/kube-prometheus-stack-grafana 2001:"
	pkill -f "^kubectl port-forward svc/kube-prometheus-stack-grafana 2101:"

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'
