variable "instance_count" {
  description = "Number of instances"
  type        = number
}

variable "ami" {
  description = "AMI ID"
  type        = string
}

variable "instance_types" {
  description = "List of instance types"
  type        = list(string)
}

variable "instance_tags" {
  description = "EC2 tags"
  type        = map(string)
}
