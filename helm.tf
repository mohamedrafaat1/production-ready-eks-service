#change HELM provider kubeconfig to your patch accordingly 
provider "helm" {
  kubernetes {
    config_path = "/home/runner/.kube/config"
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    annotations = {
      name = "prometheus"
    }

    labels = {
      mylabel = "prometheus"
    }

    name = "prometheus"
  }
depends_on = [module.eks, null_resource.file]
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    annotations = {
      name = "grafana"
    }

    labels = {
      mylabel = "grafana"
    }

    name = "grafana"
  }
depends_on = [module.eks, null_resource.file]
}

resource "helm_release" "metric-server" {
  name       = "metric-server-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"
  //version = "~> 5.10"

  set {
    name  = "apiService.create"
    value = "true"
  }
  depends_on = [module.eks, null_resource.file]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

   set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "gp2" 
  }
  set {
    name  = "server.persistentVolume.storageClass"
    value = "gp2"
  }
    depends_on = [module.eks, kubernetes_namespace.prometheus, null_resource.file]
}



resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "grafana"

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

    values = [
        "${file("./grafana.yaml")}"
    ]

  set {
    name  = "persistence.storageClassName"
    value =  "gp2" 
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  
  set {
    name  = "adminPassword"
    value = "EKS1sAWSome"
	  type  = "string"
  }
   
   set {
   name  = "service.type"
   value = "LoadBalancer"
  }
  depends_on = [module.eks, kubernetes_namespace.grafana, helm_release.prometheus, null_resource.file, aws_ec2_tag.private_subnet_shared, aws_ec2_tag.private_subnet_elb]
}


