output "alb_dns_name" {
  description = "The DNS name of the Load Balancer to access the E-Commerce Store"
  value       = aws_lb.web.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host for SSH access"
  value       = aws_instance.bastion.public_ip
}

output "web_instance_private_ips" {
  description = "Private IPs of the web server instances for Ansible"
  value       = aws_instance.web[*].private_ip
}