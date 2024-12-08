resource "null_resource" "docker_packaging" {
	  provisioner "local-exec" {
	    command = <<EOF
	    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.hello_world_app_repo.repository_url}
      docker build -t "${aws_ecr_repository.hello_world_app_repo.repository_url}:latest" .
	    docker push "${aws_ecr_repository.hello_world_app_repo.repository_url}:latest"
	    EOF
	  }
	  depends_on = [
	    aws_ecr_repository.hello_world_app_repo,
	  ]
}
