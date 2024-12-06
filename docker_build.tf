data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

resource "docker_image" "satesh_app_image" {
  name = "${aws_ecr_repository.satesh_app_repo.repository_url}:latest"
  depends_on = [aws_ecr_repository.satesh_app_repo]

  build {
    context    = "${path.module}/app"
    #dockerfile = "${path.module}/Dockerfile"
  }
}

resource "docker_registry_image" "satesh_app_push" {
  name = docker_image.satesh_app_image.name
  depends_on = [docker_image.satesh_app_image]
}
