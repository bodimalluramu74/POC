instance_count = 1

ami = "ami-0abcdef1234567890"   # Replace with valid AMI

instance_types = [
  "t2.micro",
  "t2.small",
  "t3.micro"
]

instance_tags = {
  Environment = "TQA"
  Owner       = "Ramu"
  Project     = "POC-Terraform"
}