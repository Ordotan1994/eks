# IAM roles
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "policies" {
  for_each = {
    worker   = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    cni      = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    registry = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# EKS cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [var.cluster_sg_id]
  }

  tags = var.tags
}

# Managed node group
resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-main"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_x86_64_STANDARD"
/*
  remote_access {
    ec2_ssh_key               = null
    source_security_group_ids = [var.alb_sg_id]
  }
*/

  tags = merge(
    var.tags,
    {
      "k8s.io/cluster-autoscaler/${cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"        = "TRUE"
    }
  )
}
