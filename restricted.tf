module "restricted-project-factory" {
  source              = "./modules/additi-project-factory"
  gcp_org_id          = local.common.gcp_org_id
  gcp_folder_id       = local.restricted.gcp_folder_id
  gcp_billing_account = local.common.gcp_billing_account
  gcp_project         = "${local.common.gcp_project}-restricted"
  cidr_prefix         = local.common.cidr_prefix

  members = local.restricted.project_members

  platforms = local.infrastructures.restricted.platforms

  common_authorized_networks = local.common.common_authorized_networks

  sql_database_instances = [] # [{name = "foo",tier = "db-n1-standard-1"}] # [{name = "foo"}] or []

  gke = true

  gke_node_pools = [
    {
      name         = "common-prod" # ensure to report this name in the underlying lines
      disk_type    = "pd-standard"
      image_type   = "COS" # GKE strongly advise you to use COS image type
      machine_type = "n2-standard-2"
      min_count    = 2
      max_count    = 4
    },
    {
      name         = "common-preprod" # ensure to report this name in the underlying lines
      disk_type    = "pd-standard"
      image_type   = "COS" # GKE strongly advise you to use COS image type
      machine_type = "n2-standard-2"
      min_count    = 2
      max_count    = 4
    },
  ]

  gke_node_pools_labels = {
    "all" : {},
    "common-prod" : {}
    "common-preprod" : {}
  }

  gke_node_pools_metadata = {
    "all" : {},
    "common-prod" : {}
    "common-preprod" : {}
  }

  gke_node_pools_oauth_scopes = {
    "all" : [
      "https://www.googleapis.com/auth/cloud-platform"
    ],
    "common-prod" : []
    "common-preprod" : []
  }

  gke_node_pools_tags = {
    "all" : [],
    "common-prod" : []
    "common-preprod" : []
  }

  gke_node_pools_taints = {
    "all" : [],
    "common-prod" : []
    "common-preprod" : []
  }
}

module "restricted-gitlab-variables" {
  source = "./modules/additi-gitlab-variables"

  variables = local.variables.restricted
  projects  = module.gitlab.gitlab_project.code_repos
  suffix    = "restricted"
}

module "restricted-kubernetes" {
  source                        = "./modules/additi-kubernetes"
  kubernetes_config             = module.restricted-project-factory.kubernetes_config
  platforms                     = local.infrastructures.restricted.platforms
  cloudsql_proxy_sa_private_key = module.restricted-project-factory.google_application_credentials.cloudsql_proxy_sa_private_key
  databases_credentials         = module.restricted-project-factory.databases_credentials
}

module "restricted-kube-prometheus-stack-with-grafana-install" {
  source                       = "./modules/additi-kube-prometheus-stack-with-grafana-install"
  kubernetes_config            = module.restricted-project-factory.kubernetes_config
  kube_prometheus_stack_values = <<-EOT
    grafana:
      service:
        loadBalancerIP: "${module.restricted-project-factory.grafana.load_balancer_ip}"
        loadBalancerSourceRanges:
        ${indent(4, yamlencode(module.restricted-project-factory.authorized_networks[*].cidr_block))}
        type: "LoadBalancer"
  EOT
}

module "restricted-loki" {
  source            = "./modules/additi-loki"
  kubernetes_config = module.restricted-project-factory.kubernetes_config
}

module "restricted-promtail" {
  source            = "./modules/additi-promtail"
  kubernetes_config = module.restricted-project-factory.kubernetes_config
}

module "restricted-grafana" {
  source = "./modules/additi-grafana"

  url      = "http://${module.restricted-project-factory.grafana.address}"
  username = "admin"
  password = module.restricted-kube-prometheus-stack-with-grafana-install.grafana.admin_password
}

module "restricted-argocd-install" {
  source            = "./modules/additi-argocd-install"
  kubernetes_config = module.restricted-project-factory.kubernetes_config

  argocd_values = <<-EOT
    repoServer:
      env:
      - name: ARGOCD_GIT_MODULES_ENABLED
        value: "false"
    server:
      service:
        type: "LoadBalancer"
        loadBalancerIP: "${module.restricted-project-factory.argocd.load_balancer_ip}"
        loadBalancerSourceRanges:
        ${indent(4, yamlencode(module.restricted-project-factory.authorized_networks[*].cidr_block))}
  EOT

  argocd_notifications_values = <<-EOT
    argocdUrl: https://${module.restricted-project-factory.argocd.load_balancer_ip}
  EOT

  teams_webhooks               = local.common.teams_webhooks.restricted
  api_key_argocd_notifications = module.restricted-grafana.api_key_argocd_notifications
}

module "restricted-argocd-config" {
  source = "./modules/additi-argocd-config"

  server_addr     = "${module.restricted-project-factory.argocd.address}:443"
  password        = module.restricted-argocd-install.argocd.admin_password
  insecure        = true
  applications    = local.infrastructures.restricted.argocd.applications
  target_revision = local.infrastructures.restricted.argocd.target_revision
}
