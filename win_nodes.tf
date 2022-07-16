resource "aws_iam_role" "spot_ocean_role_win" {
  name = "${var.cluster_name}-spot-win-${random_id.win.dec}"

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
		DeleteProtection = "NeverExpire"
		Terraform   = "true" 
  }
}

resource "aws_iam_role_policy_attachment" "win-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.spot_ocean_role_win.name
}

resource "aws_iam_role_policy_attachment" "win-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.spot_ocean_role_win.name
}

resource "aws_iam_role_policy_attachment" "win-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.spot_ocean_role_win.name
}

resource "aws_iam_instance_profile" "spot_profile_windows" {
  name = "${var.cluster_name}-spot-win-${random_id.win.dec}"
  role = aws_iam_role.spot_ocean_role_win.name
}
