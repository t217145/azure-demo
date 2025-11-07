locals {
  coder_db = {
    url = "postgres://${var.db_user}:${var.db_pwd}@postgres.${var.k8s_namespace}.svc.cluster.local:5432/${var.db_name}?sslmode=disable"

  }
}

resource "kubernetes_namespace" "coder_ns" {
  metadata {
    name = var.k8s_namespace
  }
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
    kubernetes_namespace.coder_ns
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


data "kubernetes_service" "coder" {
  metadata {
    name      = "coder"
    namespace = kubernetes_namespace.coder_ns.metadata[0].name
  }

  depends_on = [helm_release.coder]
}