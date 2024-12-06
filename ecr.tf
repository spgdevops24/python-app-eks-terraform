resource "aws_ecr_repository" "satesh_app_repo" {
  name                 = local.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags = {
    Name = "satesh-app-ecr"
  }
}
