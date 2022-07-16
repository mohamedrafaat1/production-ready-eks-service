resource "random_id" "linux" {
  byte_length = 8
}

resource "random_id" "win" {
  byte_length = 8
}

resource "random_id" "efs" {
  byte_length = 8
}


resource "random_id" "cni" {
  byte_length = 8
}

resource "random_id" "ebs" {
  byte_length = 8
}

resource "random_id" "fsx" {
  byte_length = 8
}
