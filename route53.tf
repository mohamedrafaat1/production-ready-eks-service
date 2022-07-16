resource "null_resource" "elb" {

  provisioner "local-exec" {
    command = "kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' > elb_${var.account_id}.json"
  }
  depends_on = [null_resource.elb, helm_release.grafana]
}

data "local_file" "elb_file" {
    filename = "elb_${var.account_id}.json"
  depends_on = [null_resource.elb, helm_release.grafana]
}


output "elb_url" {
  description = "url of grafana elb"
  value       = trimspace(data.local_file.elb_file.content)
}

#switch to account where you need DNS resolve for grafana\
#MAKE SURE TO CREATE IAM ROLE AND POLICY FOR ROUTE53 ACCESS

provider "aws" {
  alias   = "dns"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${var.route53_account}:role/route53-eks-access"
    session_name = "transit"
    external_id  = "${var.route53_account}"
  }
}


resource "aws_route53_record" "grafana_dns" {
  provider = aws.dns
  zone_id  = "0000000000"
  name     = "${var.cluster_name}.grafana.k8s.cloud"
  type     = "CNAME"
  ttl      = "172800"
  records  = [trimspace(data.local_file.elb_file.content)]
  depends_on = [data.local_file.elb_file, helm_release.grafana]

}

