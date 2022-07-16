terraform {
  backend "s3" {
    bucket = "githubactions-terraformstate"
    key    = "${var.account_id}/${var.cluster_name}/${var.state}/${var.tfname}"
    region = "us-east-1"
    access_key = var.access_key
    secret_key = var.secret_key
  }
}
