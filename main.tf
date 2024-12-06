locals {
  app_name  = "satesh-app"
  eks_name  = "Satesh-eks"
  namespace = "hello-world-app"
}

output "hello_world_app_lb_hostname" {
  value = kubernetes_service.hello_world_app_svc.status[0].load_balancer[0].ingress[0].hostname
}
