resource "aws_ecr_repository" "hello_world_app_repo" {
  name                 = local.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
	  scan_on_push = true
	}
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name = "hello-world-app-ecr"
  }
}
