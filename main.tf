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
  variables = {
    restricted = {
      REPOSITORY = {
        variable_type = "env_var"
        value         = module.additi-project-factory-restricted.container_image_registry_repository
      }
      GOOGLE_APPLICATION_CREDENTIALS = {
        variable_type = "file"
        value         = base64decode(module.additi-project-factory-restricted.google_application_credentials.ci_sa_private_key)
      }      
    }
    unrestricted = {
      REPOSITORY = {
        variable_type = "env_var"
        value         = module.additi-project-factory-unrestricted.container_image_registry_repository
      }
      GOOGLE_APPLICATION_CREDENTIALS = {
        variable_type = "file"
        value         = base64decode(module.additi-project-factory-unrestricted.google_application_credentials.ci_sa_private_key)
      }      
    }
  }
}

module "additi-gitlab" {
  source = "./modules/additi-gitlab"
  full_path     = "additi/internal/dsi-devops-engineers"
  applications  = local.applications
}

output "argocd" {
  value = {
    restricted = {
      server_addr = "${module.additi-project-factory-restricted.argocd.address}:443"
      password    = module.additi-kubernetes-restricted.argocd.admin_password
    }
    unrestricted = {
      server_addr = "${module.additi-project-factory-unrestricted.argocd.address}:443"
      password    = module.additi-kubernetes-unrestricted.argocd.admin_password
    }
  }
}