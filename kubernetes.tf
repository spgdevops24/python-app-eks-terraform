provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_auth.token
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "kubernetes_deployment" "hello_world_app_deployment" {
  metadata {
    name      = "${local.app_name}-deployment"
    labels = {
      app = "${local.app_name}"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "${local.app_name}"
      }
    }
    template {
        metadata {
            name = "${local.app_name}"
            labels = {
                app = "${local.app_name}"
            }
        }
        spec {
            container {
                name  = "${local.app_name}-container"
                image = "${aws_ecr_repository.hello_world_app_repo.repository_url}:latest"

                resources {
                    limits = {
                        cpu    = "0.5"
                        memory = "512Mi"
                    }
                    requests = {
                        cpu    = "0.25"
                        memory = "256Mi"
                    }
                }
            }
        }
    }
  }
}

resource "kubernetes_service" "hello_world_app_svc" {
  metadata {
    name      = "${local.app_name}-svc"
  }
  spec {
    selector = {
      app = "${local.app_name}"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
