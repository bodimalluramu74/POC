resource "aws_instance" "Myinstance-1" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_types[count.index]

  tags = var.instance_tags
}