# Production ready EKS cluster with Spot Ocean cluster

Full functioning EKS with Spot Ocean Cluster deployemnt 0-touch deployment in 17min
modulated for Github Actions

Requirements
-
- AWS Account ID
- VPC ID
- 2 Subnets IDs (4 optional)
- Namespaces (Up to 3 Optional)
- Automation IAM Role for EC2
- SPOT.IO Account and Auth Token
- Route53 access to add CNAME (IAM Role and Policy required)

Whats inside
-
- 2 Nodes (1 EC2 on-demand, 1 EC2 spot node)
- Grafana Pod
- Prometheus Pod
- Spot Ocean controller Pod
- Metrics Pod
- EBS CIS driver
- EFS driver (NFS)
- IRSA IAM roles for EBS/CNI/EFS
- EKS add-ons (CoreDNS, CNI, Kube-Proxy)
- Windows nodes Support in aws-auth ConfigMap
- Windows nodes Support with CoreDNS
- aws-auth ConfigMap for Azure Federated Roles SSO
- Selective Tagging up to 6 tags of your choice (key=value)
- EFS (NFS) Selective storage class creation
- Resource name randomizer

### Known Limitations
 - Grafana ELB may fail if no free Elastic-IP avalible. This is a blocker from AWS (5 EIP). Contact support to extend EIP at each account level.
 - Windows Node, refer to AWS docs.

## Infracost intergration
- You are able to estimate your EKS cluster cost<br> 
- Use Infacost for Github Actions: https://github.com/marketplace/actions/infracost-actions<br>
  Create pull request, wait to comment with cost results to appear than close the pull request.


### Tests (passing)
- EKS 1.21
  - Windows Node Server 2019
  - Jenkins Kubernetes Plugin (latest)
  - Linux Nodes
  - Node Selectors and Taints
  - Deployements
  - Spot Clusters
  - Spot Autoscaling
  - Spot Downscaling
  - Spot VNGs (mixed modes)
  - Selective tagging (partial/full/null)
  - EFS selector
  - IRSA


