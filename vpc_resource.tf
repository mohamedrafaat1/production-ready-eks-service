resource "null_resource" "vpc-resource" {

  provisioner "local-exec" {
    command = "kubectl apply -f vpc-resource-controller-configmap.yaml"
  }
  depends_on = [module.eks, null_resource.file]
}