resource "kubernetes_namespace" "hello_world_app_ns" {
  metadata {
    name = local.namespace
  }
  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_node_group.node_group
  ]
}

resource "kubernetes_deployment" "hello_world_app" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace.hello_world_app_ns.metadata[0].name
    labels = {
      app = local.app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.app_name
        }
      }
      spec {
        container {
          name  = local.app_name
          image = docker_registry_image.satesh_app_push.name
          port {
            container_port = 8080
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.hello_world_app_ns]
}

resource "kubernetes_service" "hello_world_app_svc" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace.hello_world_app_ns.metadata[0].name
    labels = {
      app = local.app_name
    }
  }
  spec {
    selector = {
      app = local.app_name
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.hello_world_app]
}
