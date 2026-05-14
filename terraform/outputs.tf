output "instance_public_ips" {
  description = "Public IP addresses for Ansible inventory to allow GitHub Actions SSH access"
  # Changed from private_ip to public_ip so the runner can connect
  value       = aws_instance.web[*].public_ip
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer to access the E-Commerce Store"
  value       = aws_lb.web.dns_name
}