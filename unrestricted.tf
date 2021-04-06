module "additi-project-factory-unrestricted" {
  source = "./modules/additi-project-factory"
  gcp_org_id          = local.common.gcp_org_id
  gcp_billing_account = local.common.gcp_billing_account
  gcp_project         = "${local.common.gcp_project}-unrestricted"
  cidr_prefix         = local.common.cidr_prefix

  members = [
    ""                                                                      # Format "group:groupname@domain"
  ]

  platforms = local.infrastructures.unrestricted.platforms

  common_authorized_networks = local.common.common_authorized_networks

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

module "unrestricted-gitlab-variables" {
  source = "./modules/additi-gitlab-variables"
  
  variables   = local.variables.unrestricted
  projects    = module.gitlab.gitlab_project.code_repos
  suffix      = "unrestricted"
}

module "unrestricted-kubernetes" {
  source = "./modules/additi-kubernetes"
  cluster                         = true
  kubernetes_config               = module.unrestricted-project-factory.kubernetes_config
  platforms                       = local.infrastructures.unrestricted.platforms
  cloudsql_proxy_sa_private_key   = module.unrestricted-project-factory.google_application_credentials.cloudsql_proxy_sa_private_key
  databases_credentials           = module.unrestricted-project-factory.databases_credentials
  argocd = {
    enable            = true
    ingress           = false
    load_balancer_ip  = module.unrestricted-project-factory.argocd.load_balancer_ip
    annotations       = module.unrestricted-project-factory.argocd.annotations
  }
  authorized_networks             = module.unrestricted-project-factory.authorized_networks
}

module "unrestricted-argocd" {
  source = "./modules/additi-argocd"

  server_addr     = "${module.unrestricted-project-factory.argocd.address}:443"
  password        = module.unrestricted-kubernetes.argocd.admin_password
  insecure        = true
  applications    = local.infrastructures.unrestricted.argocd.applications
  target_revision = local.infrastructures.unrestricted.argocd.target_revision
}