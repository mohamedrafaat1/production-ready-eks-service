resource "kubernetes_namespace" "ns1" {
  count = var.namespace_1 == "" ? 0 : 1
  metadata {
    annotations = {
      name = "${var.namespace_1}"
    }

    labels = {
      mylabel = "${var.namespace_1}"
    }

    name = "${var.namespace_1}"
  }
depends_on = [module.eks, null_resource.file]
}


