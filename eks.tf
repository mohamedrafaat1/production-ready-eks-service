#EKS 

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "18.11.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true


  cluster_addons = {

    aws-ebs-csi-driver = {
      resolve_conflicts  = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }

    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = compact(["${var.subnet1}", "${var.subnet2}", "${var.subnet3}", "${var.subnet4}"]) 

 # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
    ami_type               = "AL2_x86_64"
    disk_size              = 60
    instance_types         = ["t3.large", "m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }


  eks_managed_node_groups = {
    blue = {
      min_size     = 1
      max_size     = 10
      desired_size = 1
      instance_types = ["t3.large"]

      //enable_bootstrap_user_data = true

      //post_bootstrap_user_data = data.template_cloudinit_config.cloudinit.rendered

     tags = {
        ExtraTag = var.cluster_name
        Name = "eks-blue-node-linux"
        DeleteProtection = "NeverExpire"
        ShutDownProtection = "NeverExpire"
        Product = var.product
        BudgetTeam = var.budget
        Environment = var.environment
        EnvType = var.envtype 
        Service = var.service
      }
    }
    green = {
      min_size     = 0
      max_size     = 10
      desired_size = 0

      //nable_bootstrap_user_data = true

      //post_bootstrap_user_data = data.template_cloudinit_config.cloudinit.rendered

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "dev"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      }
      tags = {
        ExtraTag = var.cluster_name
        Name = "eks-green-node-linux"
        DeleteProtection = "NeverExpire"
        ShutDownProtection = "NeverExpire"
        Product = var.product
        BudgetTeam = var.budget
        Environment = var.environment
        EnvType = var.envtype 
        Service = var.service
       }
    }

  }

# Extend cluster security group rules
cluster_security_group_additional_rules = {
    eks_api_443_ing = {
      description                = "EKS Cluster public API 443 Cross-VPC ingress"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      cidr_blocks                = ["0.0.0.0/0"]
      //ipv6_cidr_blocks           = ["::/0"]
    }
    eks_api_3000_ing = {
      description                = "EKS Cluster public API Grafana Health Probe"
      protocol                   = "tcp"
      from_port                  = 3000
      to_port                    = 3000
      type                       = "ingress"
      cidr_blocks                = ["0.0.0.0/0"]
      //ipv6_cidr_blocks           = ["::/0"]
    }
  }

# Extend node security group rules
node_security_group_additional_rules = {
    metrics_server_8443_ing = {
      description                   = "Cluster API to metrics server 8443 ingress port"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    metrics_server_10250_ing = {
      description = "Node to node metrics server 10250 ingress port"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "ingress"
      self        = true
    }
    metrics_server_10250_eg = {
      description = "Node to node metrics server 10250 egress port"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "egress"
      self        =  true # Does not work for fargate
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-ebs-csi-${random_id.ebs.dec}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

       tags = {
        Terraform   = "true"     
        DeleteProtection = "NeverExpire"
      }
}

module "efs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-efs-csi-${random_id.efs.dec}"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

       tags = {
        Terraform   = "true"
        DeleteProtection = "NeverExpire"
      }
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-vpc_cni-${random_id.cni.dec}"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = {
    Terraform   = "true"
    DeleteProtection = "NeverExpire"
  }
}



//subnet tagging for elb
data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
}

resource "aws_ec2_tag" "private_subnet_shared" {
  for_each      = data.aws_subnet_ids.private.ids
  resource_id     = each.value
  key           = "kubernetes.io/cluster/${var.cluster_name}" 
  value         = "shared"
}
 
resource "aws_ec2_tag" "private_subnet_elb" {
  for_each      = data.aws_subnet_ids.private.ids
  resource_id     = each.value
  key           = "kubernetes.io/role/internal-elb" 
  value         = "1"
}

#FSx Ontap ISCSI - not tested on prod
//data "template_file" "iscsi_script" {
 // template = file("scripts/iscsi.sh")
//}

//data "template_cloudinit_config" "cloudinit" {
//  gzip          = false
//  base64_encode = false

 // part {
 //   content_type = "text/x-shellscript"
 //   content      = data.template_file.iscsi_script.rendered
 // }
//}