output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ssh_private_key_pem" {
  description = "Private key to SSH into the EC2 instance"
  value       = tls_private_key.example_ssh.private_key_pem
  sensitive   = true
}


