resource "aws_instance" "Myinstance-1" {
    count = var.instance_count
    ami = var.ami
    instance_type = var.instance_types[2]
    tags = var.instance_tags
  
}