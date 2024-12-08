output "hello_world_app_lb_hostname" {
  value = kubernetes_service.hello_world_app_svc.status[0].load_balancer[0].ingress[0].hostname
}