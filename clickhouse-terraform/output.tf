output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "instance_ips" {
  value = aws_instance.clickhouse[*].public_ip
}
