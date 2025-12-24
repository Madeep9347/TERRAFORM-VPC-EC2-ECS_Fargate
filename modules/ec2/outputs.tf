output "database_private_ip" {
  description = "Private IP address of the database EC2 instance"
  value       = aws_instance.database.private_ip
}
