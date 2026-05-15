variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1" 
}

variable "key_name" {
  description = "Name of the existing AWS EC2 key pair for SSH access"
  type        = string
  default     = "vockey"  # <-- THIS IS THE CRITICAL ADDITION
}

variable "instance_type" {
  description = "EC2 instance type for the application hosts"
  type        = string
  default     = "t3.micro"  
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 2 
}