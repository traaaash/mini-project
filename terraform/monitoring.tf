# --- OBSERVABILITY & AUTOMATED MESSAGING ---

# 1. SNS Topic for notifications
resource "aws_sns_topic" "cpu_alerts" {
  name = "high-cpu-utilization-alerts"
}

# 2. SNS Subscription to send emails
resource "aws_sns_topic_subscription" "admin_email_alerts" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = "admin@example.com" # As per system specification
}

# 3. CloudWatch Alarm for each EC2 instance
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  count               = var.instance_count
  alarm_name          = "High-CPU-EC2-${aws_instance.web[count.index].id}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2" # Must persist for 2 minutes
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60" # Check every minute
  statistic           = "Average"
  threshold           = 75 # 75% CPU
  alarm_description   = "Triggers when EC2 CPU exceeds 75% for 2 minutes."
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  ok_actions          = [aws_sns_topic.cpu_alerts.arn] # Also notify when the state returns to OK

  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
}