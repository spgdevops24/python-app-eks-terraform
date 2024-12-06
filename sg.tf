# Create a security group for the EKS cluster control plane
resource "aws_security_group" "cluster_sg" {
  name        = "satesh-eks-cluster-sg"
  description = "Security Group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "satesh-eks-cluster-sg"
  }
}

# Allow inbound HTTP traffic (port 80) from anywhere to the cluster
resource "aws_security_group_rule" "cluster_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster_sg.id
}

# Create a security group for the EKS nodes
resource "aws_security_group" "node_sg" {
  name        = "satesh-eks-node-sg"
  description = "Security Group for EKS nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "satesh-eks-node-sg"
  }
}

# Allow inbound NodePort range if needed (e.g., for Kubernetes NodePort services)
resource "aws_security_group_rule" "node_inbound_nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node_sg.id
}
