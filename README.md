# Satesh-Application Deployment with Terraform and EKS

## What it Does
This repository provides a Terraform configuration that:

1. Creates a VPC with public subnets.
2. Deploys an Amazon EKS cluster and associated node groups.
3. Builds and containerizes a simple Python "Hello World" application using Docker.
4. Pushes the resulting image to Amazon ECR.
5. Deploys the application onto the EKS cluster in the `hello-world-app` Kubernetes namespace.
6. Exposes the application via a LoadBalancer service so it can be accessed publicly over HTTP.

By following the provided setup and running the scripts, you can get a working "Hello World" application accessible through a public endpoint.

## Terraform Flow of Deployment
The deployment follows a clear order, enforced by Terraform dependencies:

1. **VPC Creation:**  
   The VPC, public subnets, and an Internet Gateway are created first. This provides a network foundation.
   
2. **EKS Deployment:**  
   Using the created VPC, Terraform provisions an EKS cluster and Node Groups. This step includes IAM roles and attaches the required policies.
   
3. **ECR and Docker Build:**  
   Terraform sets up an ECR repository and uses the Docker provider to build and push the application image to ECR.
   
4. **Kubernetes Deployment:**  
   Once EKS is ready, Terraform applies Kubernetes resources (Namespace, Deployment, Service) that run and expose the Python application.

5. **Public Access:**  
   A LoadBalancer service is used to provide a public endpoint for the application. Terraform outputs the load balancer URL, which you can use to access the app in your browser.

## Input Variables
The configuration uses several input variables, defined in `vars.tf`. Key inputs include:

- **aws_region:** (string) The AWS region to use. Defaults to `us-east-1`.
- **aws_profile:** (string) The AWS CLI profile to use for authentication. Defaults to `default`.
- **backend_bucket:** (string) Name of the S3 bucket used for remote Terraform state (in earlier versions you tried variables, but we ended up hardcoding in the backend file. If still using variables for bucket creation in the script, mention them.)
- **backend_key:** (string) The key (path) in the S3 bucket for the Terraform state file.
- **backend_dynamodb_table:** (string) The DynamoDB table name for Terraform state locking.

> **Note:** Since Terraform don't support use of variables in the backend resource, the `backend.tf` was updated to hardcode the backend configuration, so alway remember to update backend manually per requirement se.

## Outputs
After a successful apply, Terraform will output:

- **hello_world_app_lb_hostname:** The hostname of the LoadBalancer that fronts the "Hello World" application. Use `http://<hostname>/` in your browser to access the app.

## Why Use the deploy.sh Script
The `deploy.sh` script orchestrates the entire deployment and teardown process. 
NOTE: This depoloy.sh file uses following variables as hard-coded, so it is a good practice to review these variables as per your requirements.
    - BUCKET_NAME="python-helloworld-app-bucket"    ### CHANGE PER YOUR NEED
    - DYNAMODB_TABLE="python-helloworld-app"        ### CHANGE PER YOUR NEED
    - REGION="us-east-1"                            ### CHANGE PER YOUR NEED

It:
- Ensures prerequisites like the DynamoDB table and S3 bucket for remote state are created before initializing Terraform.
- Runs `terraform init` and then `terraform apply` without `-auto-approve`, so you have a chance to review the plan and type `yes` to proceed.
- After successful deployment, it attempts to validate that the application is accessible by querying the LoadBalancer’s endpoint.
- For teardown, it runs `terraform destroy -auto-approve`, cleaning up all resources. If any resources fail to destroy, it reports them but continues to destroy others.

This script simplifies the user experience by combining AWS resource setup, Terraform initialization, apply/destroy operations, and basic post-deployment validation into a single command.

## Usage in Totality
**Prerequisites:**
- Install and configure the AWS CLI with credentials that can create EKS, VPC, and related resources.
- Install Terraform.
- Have Docker installed locally if you’re running Terraform from a machine that can build Docker images (the Docker provider runs builds locally).

**Steps:**
1. **Clone this repository:**  
   ```bash
   git clone <this-repo-url> && cd <repo-directory>
   ```


2. **Edit Variables (If Needed):** Open vars.tf and update aws_region or aws_profile as desired.

Run the Deployment:

   ```bash
   ./deploy.sh apply
   ```

The script will:
- Create the required DynamoDB table and S3 bucket for Terraform state if they don’t exist.
- Initialize Terraform and run terraform apply.
- Build and push the Docker image to ECR.
- Deploy the EKS cluster and the Kubernetes app.
- Attempt to validate access to the LoadBalancer endpoint.
- Access the Application: After the deployment is complete, the script prints the LoadBalancer URL. Open it in your browser to see the "Hello World" greeting:

   ```bash
   curl http://<LoadBalancer-Hostname>/
   ```


3. **Teardown (Cleanup):** To remove all resources created:

   ```bash
   ./deploy.sh destroy
   ```
The script will attempt to destroy all resources. It uses -auto-approve for convenience.