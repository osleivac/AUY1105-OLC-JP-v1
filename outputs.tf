output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.AUY1105-tiendatech-ec2.id
}


output "public_ip" {
  description = "IP publica de la instancia EC2"
  value       = aws_instance.AUY1105-tiendatech-ec2.public_ip
}
