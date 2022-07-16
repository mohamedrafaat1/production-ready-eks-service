 data "aws_eks_cluster" "self" {
  name = var.cluster_name
  depends_on = [module.eks]
}
 

locals {
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_without_http = replace(local.cluster_oidc_issuer_url, "https://", "")
}

resource "helm_release" "kubernetes_efs_csi_driver" {

  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
  timeout    = 600

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
    type  = "string"
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver"
    type  = "string"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
    type  = "string"
  }
  depends_on = [module.eks, null_resource.file]
}

