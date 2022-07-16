output "spot_role_arn_win" {
    value = aws_iam_role.spot_ocean_role_win.arn 
}

output "spot_profile_name_win" {
    value = aws_iam_instance_profile.spot_profile_windows.name
}

output "spot_role_arn" {
    value = aws_iam_role.spot_ocean_role.arn 
}

output "spot_profile_name" {
    value = aws_iam_instance_profile.spot_profile_linux.name
}

output "spot_account_id" {
  description = "ID of spot account"
  value       = trimspace(data.local_file.spot_file.content)
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "grafana_url" {
  description = "route53 A record"
  value       = aws_route53_record.grafana_dns.name
}

output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}



