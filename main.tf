locals {
  common = {
    gcp_org_id          = ""                              # gcloud organizations list --filter="displayName=XXXX" --format="value(name)"
    gcp_folder_id       = ""                              # gcloud resource-manager folders list --organization [ORG_ID]
    gcp_billing_account = ""                              # gcloud beta billing accounts list --filter="displayName=YYYY" --format="value(name)"
    gcp_project         = ""                              # e.g. ofi-common    -name must be 4 to 30 characters with lowercase and uppercase letters, numbers, hyphen, single-quote, double-quote, space, and exclamation point.        demo-devops-5d4e project_id contains prohibited words
    cidr_prefix         = ""                              # Search Confluence : Attribution+des+CIDR
    common_authorized_networks = [
      { cidr_block = "x.y.w.z/32", display_name = "custom IP" },
    ]
    gitlab_full_path    = ""                              # e.g. gitlabInstance/internal/bu-immobilier

    teams_webhooks = {
      restricted = {
        deploy-ofi-common-restricted = ""
      }
      unrestricted = {
        deploy-ofi-common-unrestricted = ""
      }
    }

  }
}

locals {
  app1_name = "app-name"
  #app2_name = "app-name"
  applications = {
    (local.app1_name) = {
      infrastructures = {
        restricted    = formatlist("${local.app1_name}-%s",["preproduction", "production"]),
        unrestricted  = formatlist("${local.app1_name}-%s",["recette1","recette2","recette3"]),
      }
      gitlab = {
        code = {
          import_url                                       = ""
          default_branch                                   = "develop"
          merge_method                                     = "ff"
          only_allow_merge_if_all_discussions_are_resolved = true
          snippets_enabled                                 = true
          tags                                             = []
          wiki_enabled                                     = true
        }
        manifest = {
          import_url       = ""
          default_branch   = "unrestricted"
          snippets_enabled = true
          tags             = []
          wiki_enabled     = true
        }
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
      url       = try(module.gitlab.gitlab_project.manifest_repos[local.app1_name].http_url_to_repo, "")
      username  = try(module.gitlab.gitlab_deploy_token.deploy_tokens[local.app1_name].username, "")
      password  = try(module.gitlab.gitlab_deploy_token.deploy_tokens[local.app1_name].token, "")
    }
    # (local.app2_name) = {
    #   url       = try(module.gitlab.gitlab_project.manifest_repos[local.app2_name].http_url_to_repo, "")
    #   username  = try(module.gitlab.gitlab_deploy_token.deploy_tokens[local.app2_name].username, "")
    #   password  = try(module.gitlab.gitlab_deploy_token.deploy_tokens[local.app2_name].token, "")
    # }
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
        value         = module.restricted-project-factory.container_image_registry_repository
      }
      GOOGLE_APPLICATION_CREDENTIALS = {
        variable_type = "file"
        value         = base64decode(module.restricted-project-factory.google_application_credentials.ci_sa_private_key)
      }      
    }
    unrestricted = {
      REPOSITORY = {
        variable_type = "env_var"
        value         = module.unrestricted-project-factory.container_image_registry_repository
      }
      GOOGLE_APPLICATION_CREDENTIALS = {
        variable_type = "file"
        value         = base64decode(module.unrestricted-project-factory.google_application_credentials.ci_sa_private_key)
      }      
    }
  }
}

module "gitlab" {
  source = "./modules/additi-gitlab"
  full_path     = local.common.gitlab_full_path
  applications  = local.applications
}

output "argocd" {
  value = {
    restricted = {
      server_addr = "${module.restricted-project-factory.argocd.address}:443"
      password    = module.restricted-kubernetes.argocd.admin_password
    }
    unrestricted = {
      server_addr = "${module.unrestricted-project-factory.argocd.address}:443"
      password    = module.unrestricted-kubernetes.argocd.admin_password
    }
  }
}
