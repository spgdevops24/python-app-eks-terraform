resource "aws_eks_cluster" "eks" {
  name     = local.eks_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.cluster_sg.id]
  }

  tags = {
    Name = local.eks_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_vpc.main
  ]
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
  depends_on = [aws_eks_cluster.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
  depends_on = [aws_eks_cluster.eks]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  #additional_security_groups = [aws_security_group.node_sg.id]

  tags = {
    Name = "satesh-eks-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}
