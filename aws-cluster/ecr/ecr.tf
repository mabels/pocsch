
variable "ecr_repros" {
  type = "list"
  default = [ 
    { name = "ecr" },
    { name = "ecr1" } 
  ] 
}


resource "aws_ecr_repository" "pocsch_ecr_repros" {
  count = "${length(var.ecr_repros)}"
  name = "${lookup(var.ecr_repros[count.index], "name")}"
}

