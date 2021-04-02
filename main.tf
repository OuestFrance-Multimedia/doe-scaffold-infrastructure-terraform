locals {
  app1_name = "app-name"
  #app2_name = "app-name"
  applications = {
    (local.app1_name) = {
      infrastructures = {
        restricted    = formatlist("${local.app1_name}-%s",["preproduction", "production"]),
        unrestricted  = formatlist("${local.app1_name}-%s",["recette1","recette2","recette3"]),
      }
    }
    #(local.app2_name) = {
    #  infrastructures = {
    #    restricted    = formatlist("${local.app2_name}-%s",["preproduction", "production"]),
    #    unrestricted  = formatlist("${local.app2_name}-%s",["recette1","recette2","recette3"]),
    #  }
    #}
  }
  sources = {
    (local.app1_name) = {
      url       = try(module.additi-gitlab.gitlab_project.manifest_repos[local.app1_name].http_url_to_repo, "")
      username  = try(module.additi-gitlab.gitlab_deploy_token.deploy_tokens[local.app1_name].username, "")
      password  = try(module.additi-gitlab.gitlab_deploy_token.deploy_tokens[local.app1_name].token, "")
    }
    #(local.app2_name) = {
    #  url       = try(module.additi-gitlab.gitlab_project.manifest_repos[local.app2_name].http_url_to_repo, "")
    #  username  = try(module.additi-gitlab.gitlab_deploy_token.deploy_tokens[local.app2_name].username, "")
    #  password  = try(module.additi-gitlab.gitlab_deploy_token.deploy_tokens[local.app2_name].token, "")
    #}
  }
  infrastructures = {
    restricted = {
      platforms = flatten([ for app in local.applications : app.infrastructures.restricted ])
      argocd = {
        enable = true
        ingress = false
        target_revision = "restricted"
        applications = {
          for k,v in local.applications : 
          k => {
            source     = local.sources[k]
            platforms  = local.applications[k].infrastructures.restricted
          }
        }
      }
    }
    unrestricted = {
      platforms = flatten([ for app in local.applications : app.infrastructures.unrestricted ])
      argocd = {
        enable = true
        ingress = false
        target_revision = "unrestricted"
        applications = {
          for k,v in local.applications : 
          k => {
            source     = local.sources[k]
            platforms  = local.applications[k].infrastructures.unrestricted
          }
        }
      }
    }
  }
}

module "additi-gitlab" {
  source = "./modules/additi-gitlab"
  full_path     = "additi/internal/dsi-devops-engineers"
  applications  = local.applications
}