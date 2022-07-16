variable cluster_name {}
variable vpc_id {}
variable subnet1 {}
variable subnet2 {}
variable subnet3 {}
variable subnet4 {}
variable account_id {}
variable automation_role {}
variable namespace_1 {}

variable "efs_storage_class" {
  description = "If set to true, enable"
  type        = bool
}

variable product {
  default = "k8s"
}

variable budget {
  default = "none"
}

variable environment {
  default = "dev"
}

variable envtype {
  default = "dev"
}

variable service {
  default = "eks"
}


