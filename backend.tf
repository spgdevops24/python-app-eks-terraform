terraform {
  backend "s3" {
    bucket         = "python-helloworld-app-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "python-helloworld-app"
    encrypt        = true
  }
}

