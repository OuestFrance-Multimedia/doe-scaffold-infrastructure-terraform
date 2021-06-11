# Infos

Check Makefile to understand module precedence

# Bootstrap or update the project

1. Clone this repo localy

2. Pull submodules

```shell
git submodule update --init --recursive
```

3. Customise locals in main.tf according to your needs

4. Update members in restricted & unrestricted files according to your needs.

5. Add the script directory of [this repo](git@gitlab.com:additi/internal/dsi-devops-engineers/infrastructure-configuration-docker-gitlabci-terraform.git) to your PATH

6. export GITLAB_TOKEN and GITLAB_USERNAME in your env

7. export the SA Google application credentials to your env. generate  it from the /internal/dsi-devops-engineers/infrastructure-terraform-gcp-org-of2m.fr repo. 

    export GOOGLE_APPLICATION_CREDENTIALS=/home/olivier/git/gitlab-additi/internal/dsi-devops-engineers/infrastructure-terraform-gcp-org-of2m.fr/credentials/terraform-sa.json

8. Load external scripts to your `$PATH`

    clone git@gitlab.com:additi/internal/dsi-devops-engineers/tools/infrastructure-configuration-docker-gitlabci-terraform.git
and add scripts directory to your `$PATH`

9. init terraform using http backend method :

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
