output "instance_ips" {
  description = "IP addresses of the EC2 instances for Ansible inventory"
  # We use private_ip because the instances are in Private Subnets per the architecture
  value       = aws_instance.web[*].private_ip
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer to access the E-Commerce Store"
  value       = aws_lb.web.dns_name
}