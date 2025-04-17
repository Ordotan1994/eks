resource "helm_release" "autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.46.6"

  timeout    = 600
  wait       = true

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "awsRegion"
    value = var.region
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ca.arn
  }

  depends_on = [aws_iam_role_policy.ca_policy]
}

# IRSA role (minimal policy from AWS docs)
data "aws_iam_policy_document" "ca" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ca" {
  name               = "${var.cluster_name}-cluster-autoscaler-irsa"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.oidc.arn },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          for_key = replace(aws_iam_openid_connect_provider.oidc.url, "https://", "") 
          for_value = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "ca_policy" {
  role   = aws_iam_role.ca.id
  policy = data.aws_iam_policy_document.ca.json
}
