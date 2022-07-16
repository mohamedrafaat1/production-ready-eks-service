data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}


data "aws_eks_cluster" "this" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
}



locals {

  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })

  # we have to combine the configmap created by the eks module with the externally created node group/profile sub-modules
  aws_auth_configmap_yaml = <<-EOT
  ${chomp(module.eks.aws_auth_configmap_yaml)}
      - rolearn: arn:aws:iam::${var.account_id}:role/spot-ocean-node-role-lin-${var.cluster_name}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
      - rolearn: arn:aws:iam::${var.account_id}:role/spot-ocean-node-role-win-${var.cluster_name}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
          - eks:kube-proxy-windows
      - rolearn: arn:aws:iam::${var.account_id}:role/Automation
        username: Admin
        groups:
          - system:masters
      - rolearn: arn:aws:iam::${var.account_id}:role/${var.automation_role}
        username: ${var.automation_role}
        groups:
          - system:masters
      - rolearn: arn:aws:iam::${var.account_id}:role/Admin
        username: Admin
        groups:
          - system:masters
      - rolearn: arn:aws:iam::${var.account_id}:role/DevOps
        username: developer-viewer
  EOT
}

resource "null_resource" "patch" {
  depends_on = [null_resource.file]
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
    cmd_patch  = "kubectl patch configmap/aws-auth --patch \"${local.aws_auth_configmap_yaml}\" -n kube-system --kubeconfig /home/runner/.kube/config"
  
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
    command = self.triggers.cmd_patch
  }
}


resource "time_sleep" "wait_60_seconds" {
  depends_on = [module.eks]

  create_duration = "60s"
}

resource "null_resource" "file" {

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${var.cluster_name}"
  }
  depends_on = [time_sleep.wait_60_seconds]
}

