variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "instance_name" {
  description = "The name tag for the EC2 instance"
  type        = string
  default     = "myAWSLinuxVM"
}
