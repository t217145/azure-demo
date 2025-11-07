locals {
  coder_db = {
    url = "postgres://${var.db_user}:${var.db_pwd}@postgres.${var.k8s_namespace}.svc.cluster.local:5432/${var.db_name}?sslmode=disable"

  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.name_prefix}-dns"

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_account" "storage" {
  name                     = replace(var.name_prefix, "-", "")
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_share" "file_share" {
  name                    = "fileshare"
  storage_account_name    = azurerm_storage_account.storage.name
  quota                   = var.file_share_size_gb
  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_role_assignment" "aks_to_storage" {
  principal_id          = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name  = "Storage File Data SMB Share Contributor"
  scope                 = azurerm_storage_account.storage.id
  depends_on = [ 
    azurerm_storage_account.storage,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "kubernetes_namespace" "coder_ns" {
  metadata {
    name = var.k8s_namespace
  }
  depends_on = [ 
    azurerm_kubernetes_cluster.aks
  ]
}

# Secret for Postgres credentials
resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.coder_ns.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_pwd
    POSTGRES_DB       = var.db_name
  }

  depends_on = [ 
    azurerm_kubernetes_cluster.aks
  ]
}

resource "kubernetes_manifest" "postgres_deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "postgres"
      namespace = kubernetes_namespace.coder_ns.metadata[0].name
      labels = {
        app = "postgres"
      }
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "postgres"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "postgres"
          }
        }
        spec = {
          containers = [
            {
              name  = "postgres"
              image = "postgres:15"
              ports = [
                {
                  containerPort = 5432
                }
              ]
              envFrom = [
                {
                  secretRef = {
                    name = kubernetes_secret.postgres_secret.metadata[0].name
                  }
                }
              ]
              volumeMounts = [
                {
                  name      = "pgdata"
                  mountPath = "/var/lib/postgresql/data"
                }
              ]
            }
          ]
          volumes = [
            {
              name = "pgdata"
              emptyDir = {}
            }
          ]
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.postgres_secret
  ]
}

resource "kubernetes_manifest" "postgres_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "postgres"
      namespace = kubernetes_namespace.coder_ns.metadata[0].name
    }
    spec = {
      type = "ClusterIP"
      selector = {
        app = "postgres"
      }
      ports = [
        {
          port       = 5432
          targetPort = 5432
        }
      ]
    }
  }
  depends_on = [
    kubernetes_secret.postgres_secret
  ]
}

resource "kubernetes_secret" "coder_db_url" {
  metadata {
    name      = "coder-db-url"
    namespace = kubernetes_namespace.coder_ns.metadata[0].name
  }

  type = "Opaque"

  data = {
    url = local.coder_db.url
  }

  depends_on = [
    kubernetes_manifest.postgres_service
  ]
}
 
resource "helm_release" "coder" {
  name       = "coder"
  namespace  = kubernetes_namespace.coder_ns.metadata[0].name
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "2.22.1"
 
  values = [
    yamlencode(
      {
        coder = {
          env = [
            {
              name = "CODER_PG_CONNECTION_URL"
              valueFrom = {
                secretKeyRef = {
                  name = kubernetes_secret.coder_db_url.metadata[0].name
                  key  = "url"
                }
              }
            },
            {
              name  = "CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE"
              value = "true"
            }
          ]
          resources = {
            limits = {
              cpu    = "500m"
              memory = "1024Mi"
            }
            requests = {
              cpu    = "500m"
              memory = "1024Mi"
            }
          }
        }
      }
    )
  ]

  depends_on = [
    kubernetes_secret.coder_db_url
  ]
}