provider "aws" {
  region = "eu-west-1"
}

variable "eks_cluster_name" {
  default = "eks-msk-cluster-poc"
  type = string
}

variable "default_vpc_id" {
}

variable "default_subnet_ids" {
}

resource "aws_iam_role" "eks-msk-poc-cluster-role" {
  name = "eks-mks-poc-cluster-role"

  assume_role_policy = jsonencode({
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "eks.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ],
    Version: "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-msk-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks-msk-poc-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-msk-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.eks-msk-poc-cluster-role.name
}

resource "aws_cloudwatch_log_group" "eks_log_group" {
  name = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks_node_group_role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-msk-poc-node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks-msk-poc-node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks-msk-poc-node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_node_group_role.name
}


resource "aws_eks_cluster" "eks-msk-cluster-poc" {
  name = var.eks_cluster_name
  role_arn = aws_iam_role.eks-msk-poc-cluster-role.arn
  version = "1.15"

  vpc_config {
    subnet_ids = var.default_subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-msk-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-msk-AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks_log_group
  ]
}

resource "aws_eks_node_group" "eks-msk-cluster-poc_node_group" {
  cluster_name = aws_eks_cluster.eks-msk-cluster-poc.name
  node_group_name = "small_node_group"
  node_role_arn = aws_iam_role.eks_node_group_role.arn
  subnet_ids = var.default_subnet_ids
  remote_access {
    ec2_ssh_key = "PANDA-71-Keypair"
  }

  scaling_config {
    desired_size = 1
    max_size = 10
    min_size = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-msk-poc-node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-msk-poc-node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-msk-poc-node-group-AmazonEC2ContainerRegistryReadOnly,
  ]
}


output "endpoint" {
  value = aws_eks_cluster.eks-msk-cluster-poc
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-msk-cluster-poc.certificate_authority.0.data
}
