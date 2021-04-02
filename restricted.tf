module "additi-project-factory-restricted" {
  source = "./modules/additi-project-factory"
  gcp_org_id          = ""                                                  # `gcloud organizations list`
  gcp_billing_account = ""                                                  # `gcloud beta billing accounts list`
  gcp_project         = "ci-cd-pipeline"                                    # Confluence /display/DSI/Provisionning#Provisionning-CNPGCP !! DO NOT INCLUDE `-[restricted|unrestricted]` suffix here
  cidr_prefix         = "10.13"                                             # Confluence

  members = [
    ""                                                                      # Format "group:groupname@domain"
  ]

  platforms = local.infrastructures.restricted.platforms

  common_authorized_networks = [
    { cidr_block = "x.y.w.z/32", display_name = "custom IP" },
  ]

  sql_database_instances = []                                               # [{name = "foo",tier = "db-n1-standard-1"}] # [{name = "foo"}] or []

  gke = true

  gke_node_pools = [{
    name         = "stoic-swirles"                                          # ensure to report this name in the underlying lines
    disk_type    = "pd-standard"
    image_type   = "COS"                                                    # GKE strongly advise you to use COS image type
    machine_type = "n2-standard-2"
    min_count    = 2
    max_count    = 4
  }]

  gke_node_pools_labels = [{
    "all" : {},
    "stoic-swirles" : {}
  }]

  gke_node_pools_metadata = [{
    "all" : {},
    "stoic-swirles" : {}
  }]

  gke_node_pools_oauth_scopes = [{
    "all" : [
      "https://www.googleapis.com/auth/cloud-platform"
    ],
    "stoic-swirles" : []
  }]

  gke_node_pools_tags = [{
    "all" : [],
    "stoic-swirles" : []
  }]

  gke_node_pools_taints = [{
    "all" : [],
    "stoic-swirles" : []
  }]
}

module "additi-gitlab-variables-restricted" {
  source = "./modules/additi-gitlab-variables"
  
  variables   = local.variables.restricted
  projects    = module.additi-gitlab.gitlab_project.code_repos
  suffix      = "RESTRICTED"
}

module "additi-kubernetes-restricted" {
  source = "./modules/additi-kubernetes"
  cluster                         = true
  kubernetes_config               = module.additi-project-factory-restricted.kubernetes_config
  platforms                       = local.infrastructures.restricted.platforms
  cloudsql_proxy_sa_private_key   = module.additi-project-factory-restricted.google_application_credentials.cloudsql_proxy_sa_private_key
  databases_credentials           = module.additi-project-factory-restricted.databases_credentials
  argocd                          = {
    enable            = true
    ingress           = false
    load_balancer_ip  = module.additi-project-factory-restricted.argocd.load_balancer_ip
    annotations       = module.additi-project-factory-restricted.argocd.annotations
  }
  authorized_networks             = module.additi-project-factory-restricted.authorized_networks
}

module "additi-argocd-restricted" {
  source = "./modules/additi-argocd"

  server_addr     = "${module.additi-project-factory-restricted.argocd.address}:443"
  password        = module.additi-kubernetes-restricted.argocd.admin_password
  insecure        = true
  applications    = local.infrastructures.restricted.argocd.applications
  target_revision = local.infrastructures.restricted.argocd.target_revision
}

