# Infos

This is a 5 steps creation terraform workflow
  1. Follow the the pre-apply path
  2. terraform apply -target 'module.additi-gitlab'
  3. terraform apply -target 'module.additi-project-factory'
  4. terraform apply -target 'module.additi-project-argocd'
  5. terraform apply -target 'module.additi-project-kubernetes'

# pre-apply path

1. Clone this repo localy

2. Pull submodules

```shell
git submodule update --init --recursive --remote
```

3. Add the script directory of [this repo](git@gitlab.com:additi/internal/dsi-devops-engineers/infrastructure-configuration-docker-gitlabci-terraform.git) to your PATH

4. export GITLAB_TOKEN and GITLAB_USERNAME in your env

5. init terraform using http backend method :

```
terraform init \
    -reconfigure \
    -backend-config="address=https://gitlab.com/api/v4/projects/[PROJECT_ID]/terraform/state/tfstate" \
    -backend-config="lock_address=https://gitlab.com/api/v4/projects/[PROJECT_ID]/terraform/state/tfstate/lock" \
    -backend-config="unlock_address=https://gitlab.com/api/v4/projects/[PROJECT_ID]/terraform/state/tfstate/lock" \
    -backend-config="username=${GITLAB_USERNAME}" \
    -backend-config="password=${GITLAB_TOKEN}" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"
```

Or use the `gitlab_terraform_init` from the devops cli tool provided on github
