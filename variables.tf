variable "instance_type" {
    type = string
    default = "t3.micro"
  
}

variable "ami" {
    type = string
    default = "ami-0521cb2d60cfbb1a6"
}

variable "instance_count" {
    type = number
    default = 2
  }

variable "instance_types" {
    type = list(string)
    default = ["t3.micro","t3.small","t3.medium","t3.large"]
  
}

variable "instance_tags" {
    type = map(string)
    default = {
      "name" = "my-first_intance"
      "Environment"= "DEV"
    }
  
}

