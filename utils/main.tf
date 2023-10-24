resource "aws_ecr_repository" "foo" {
  name                 = "bar"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


module "default_sqs" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs?ref=v4.0.1"

  name = "keda-queue"
}