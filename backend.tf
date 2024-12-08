terraform {
  backend "s3" {
    bucket         = "python-helloworld-app-bucket"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "python-helloworld-app"
    encrypt        = true
  }
}

