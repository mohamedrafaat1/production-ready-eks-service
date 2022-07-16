 module "efs" {
   count   = var.efs_storage_class ? 1 : 0

  source  = "cloudposse/efs/aws"
  version = "0.31.1"

  region = "us-east-1"

  vpc_id  = var.vpc_id
  subnets = compact(["${var.subnet1}", "${var.subnet2}", "${var.subnet3}", "${var.subnet4}"])

  transition_to_ia    = "AFTER_7_DAYS"
  
  // NOTE: the module is stupid and puts this tag on the security group and access point as well
  tags = {
    Name = "${var.cluster_name}-state-efs"
  }

  security_group_rules = [
    
   {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      cidr_blocks              = []
      source_security_group_id = data.aws_eks_cluster.self.vpc_config[0].cluster_security_group_id //flatten([module.eks.cluster_security_group_id]) data.aws_eks_cluster.self.vpc_config[0].cluster_security_group_id
      description              = "Allow ingress traffic to EFS from primary EKS security group"  
    }
  ]
   depends_on = [module.eks]
}

 resource "aws_efs_backup_policy" "policy" {
  count   = var.efs_storage_class ? 1 : 0
  file_system_id = module.efs[count.index].id

  backup_policy {
    status = "ENABLED"
  }
  depends_on = [module.efs]
}

output "efs_id" {
  value       = module.efs.*.id
  description = "EFS id"
}

variable "reclaim_policy" {
  default = "Retain"
}

 resource "kubernetes_storage_class" "storage_class" {
  count   = var.efs_storage_class ? 1 : 0
  
  storage_provisioner = "efs.csi.aws.com"
   reclaim_policy = var.reclaim_policy
   allow_volume_expansion = true
   metadata {
     name = "efs-sc"
   }
   parameters = {
     provisioningMode = "efs-ap"
     fileSystemId = module.efs[count.index].id
     directoryPerms = "700"
   }
   depends_on = [helm_release.kubernetes_efs_csi_driver, null_resource.file, module.efs]
 }
