
resource "null_resource" "spot_account" {

  provisioner "local-exec" {
    command = "curl https://api.spotinst.io/setup/account?cloudAccountId=${var.account_id} -H \"Accept: application/json\" -H \"Authorization: Bearer "$var.spot_io_barier}"\" | jq -r '.response.items[0].accountId' > spot_${var.account_id}.json"
  }
}

data "local_file" "spot_file" {
    filename = "spot_${var.account_id}.json"
  depends_on = [null_resource.spot_account]
}


provider "spotinst" {
   token   = "${var.spot_io_auth_token}"
   account = trimspace(data.local_file.spot_file.content)
}

module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"

  # Credentials.
  spotinst_token   = "${var.spot_io_auth_token}"
  spotinst_account = trimspace(data.local_file.spot_file.content) 

  # Configuration.
  cluster_identifier = var.cluster_name
  depends_on = [module.eks, data.local_file.spot_file]
}

resource "aws_iam_role" "spot_ocean_role" {
  name = "${var.cluster_name}-spot-lin-${random_id.linux.dec}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
    Terraform   = "true"
    DeleteProtection = "NeverExpire"
  }
}


resource "aws_iam_role_policy_attachment" "lin-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.spot_ocean_role.name
}

resource "aws_iam_role_policy_attachment" "lin-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.spot_ocean_role.name
}

resource "aws_iam_role_policy_attachment" "lin-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.spot_ocean_role.name
}

resource "aws_iam_instance_profile" "spot_profile_linux" {
  name = "${var.cluster_name}-spot-lin-${random_id.linux.dec}"
  role = aws_iam_role.spot_ocean_role.name
}

locals {
  worker_user_data = <<EOT
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name}
EOT
}


resource "spotinst_ocean_aws" "spot_ocean_cluster" {
  name = var.cluster_name
  controller_id = var.cluster_name

  autoscaler {
    autoscale_is_enabled = true
    resource_limits {
      max_vcpu = 100000
      max_memory_gib = 20000
    }
  }
  
  desired_capacity = 1
  min_size = 1
  max_size = 1000
  subnet_ids = compact(["${var.subnet1}", "${var.subnet2}", "${var.subnet3}", "${var.subnet4}"])
  image_id = "ami-0e1b6f116a3733fef"
  user_data = local.worker_user_data
  security_groups = flatten([module.eks.node_security_group_id])
  root_volume_size = 120
  iam_instance_profile = aws_iam_instance_profile.spot_profile_linux.name
  #whitelist  = ["t1.micro", "m1.small", "t3.large", "m6i.large", "m5.large", "m5n.large", "m5zn.large"]

  tags {
    key = "AutoTag_CreateTime"
    value = timestamp()
  }

  tags {
    key = "AutoTag_Creator"
    value = "1"
  }

  tags {
    key = "AutoTag_InvokedBy"
    value = "eks-nodegroup.amazonaws.com"
  }

  tags {
    key = "eks:cluster-name"
    value = var.cluster_name
  }

  tags {
    key = "eks:nodegroup-name"
    value = var.cluster_name
  }

  tags {
    key = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value = "owned"
  }

  tags {
    key = "k8s.io/cluster-autoscaler/enabled"
    value = "true"
  }

  tags {
    key = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
  }

  tags {
    key = "DeleteProtection"
    value = "NeverExpire"
  }

    tags {
   key = "ShutDownProtection"
    value = "NeverExpire"
  }

    tags {
    key = "Product"
    value = var.product
  }

    tags {
    key = "BudgetTeam"
    value = var.budget
 }

   tags {
    key = "Environment"
    value = var.environment
 }

  tags {
    key = "EnvType"
    value = var.envtype 
  }

    tags {
    key = "Service"
    value = var.service
  }

   tags {
    key = "Name"
    value = "eks-spot-node-linux"
  }
   
    tags {
    key = "Terraform"
    value = "true"
  }

  region = "us-east-1"
  depends_on = [module.eks, aws_iam_role.spot_ocean_role, aws_iam_instance_profile.spot_profile_linux]
}
