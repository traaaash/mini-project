output "instance_public_ips" {
  description = "Public IP addresses of the application EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}
