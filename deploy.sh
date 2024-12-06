#!/usr/bin/env bash
set -e

ACTION="$1"

if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    echo "Usage: $0 [apply|destroy]"
    exit 1
fi

# Variables for resources created outside of Terraform
BUCKET_NAME="python-helloworld-app-bucket"
DYNAMODB_TABLE="python-helloworld-app"
REGION="us-east-1"

if [[ "$ACTION" == "apply" ]]; then
    # Create DynamoDB table for TF state locking if it doesn't exist
    if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
        echo "Creating DynamoDB table $DYNAMODB_TABLE..."
        aws dynamodb create-table \
          --table-name "$DYNAMODB_TABLE" \
          --attribute-definitions AttributeName=LockID,AttributeType=S \
          --key-schema AttributeName=LockID,KeyType=HASH \
          --billing-mode PAY_PER_REQUEST \
          --region "$REGION"
        
        # Wait for the table to be in ACTIVE state
        aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
        echo "DynamoDB table $DYNAMODB_TABLE created."
    else
        echo "DynamoDB table $DYNAMODB_TABLE already exists. Skipping creation."
    fi

    # Create S3 bucket for TF state if it doesn't exist
    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "Creating S3 bucket $BUCKET_NAME..."
        aws s3 mb s3://"$BUCKET_NAME" --region "$REGION"
        echo "S3 bucket $BUCKET_NAME created."
    else
        echo "S3 bucket $BUCKET_NAME already exists. Skipping creation."
    fi

    # Now that the backend resources exist, initialize Terraform
    terraform init

    # Apply with auto-approve to avoid prompt user input
    terraform apply --auto-approve

    # After apply, get the service load balancer endpoint
    LB_HOSTNAME=$(terraform output -raw hello_world_app_lb_hostname 2>/dev/null || true)
    if [ -z "$LB_HOSTNAME" ]; then
        # Attempt to retrieve from kubernetes service if terraform output not defined
        echo "Fetching LoadBalancer hostname..."
        LB_HOSTNAME=$(kubectl get svc -n hello-world-app satesh-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') || true
    fi

    if [ -z "$LB_HOSTNAME" ]; then
        echo "Cannot fetch LoadBalancer hostname. Please wait a moment and try again."
        exit 1
    fi

    echo "Validating application accessibility at http://$LB_HOSTNAME ..."
    for i in {1..10}; do
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$LB_HOSTNAME/)
        if [ "$STATUS_CODE" = "200" ]; then
            echo "SUCCESS !!! Application is accessible. Status code: $STATUS_CODE"
            echo "Contents from the Python App: $(curl -s http://$LB_HOSTNAME/)"
            exit 0
        else
            echo "Waiting for application to become accessible (attempt $i)..."
            sleep 10
        fi
    done

    echo "Application not accessible after multiple attempts."
    exit 1

elif [[ "$ACTION" == "destroy" ]]; then

    # Get a list of all resources in the state
    ALL_RESOURCES=$(terraform state list)

    # Create arrays for each category
    k8s_services=()
    k8s_deployments=()
    k8s_namespaces=()
    eks_node_groups=()
    eks_clusters=()

    # Populate arrays by filtering ALL_RESOURCES
    while IFS= read -r resource; do
    case "$resource" in
        kubernetes_service.*)
        k8s_services+=("$resource")
        ;;
        kubernetes_deployment.*)
        k8s_deployments+=("$resource")
        ;;
        kubernetes_namespace.*)
        k8s_namespaces+=("$resource")
        ;;
        aws_eks_node_group.*)
        eks_node_groups+=("$resource")
        ;;
        aws_eks_cluster.*)
        eks_clusters+=("$resource")
        ;;
        *)
        ;;
    esac
    done <<< "$ALL_RESOURCES"

    # Combine the matched arrays into one ordered array
    ordered_resources=(
        "${k8s_services[@]}"
        "${k8s_deployments[@]}"
        "${k8s_namespaces[@]}"
        "${eks_node_groups[@]}"
        "${eks_clusters[@]}"
    )

    # Destroy the ordered resources first
    for r in "${ordered_resources[@]}"; do
        echo "Destroying: $r"
        terraform destroy -target="$r" -auto-approve || true
    done
    terraform destroy -auto-approve || true

    # Delete S3 bucket
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "Emptying and deleting S3 bucket $BUCKET_NAME..."
        # Remove all objects from the bucket
        aws s3 rm s3://"$BUCKET_NAME" --recursive || true
        # Delete the bucket
        aws s3 rb s3://"$BUCKET_NAME" --force || true
        echo "S3 bucket $BUCKET_NAME deleted."
    else
        echo "S3 bucket $BUCKET_NAME not found or already deleted."
    fi

    # Delete DynamoDB table
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
        echo "Deleting DynamoDB table $DYNAMODB_TABLE..."
        aws dynamodb delete-table --table-name "$DYNAMODB_TABLE" --region "$REGION"
        aws dynamodb wait table-not-exists --table-name "$DYNAMODB_TABLE" --region "$REGION" || true
        echo "DynamoDB table $DYNAMODB_TABLE deleted."
    else
        echo "DynamoDB table $DYNAMODB_TABLE not found or already deleted."
    fi
    echo "Destroy process completed."

    echo "NOTE: To avoid unnecessary cost Billings from the AWS Cloud, Check Terraform logs for any undestroyed resources."
    echo "Below is the statefile list: (If-Not-Empty 'These may need to be destroyed manually')."
    terraform state list
fi
