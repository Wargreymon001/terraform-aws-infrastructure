output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id #VAMOS A MOSTRAR EL ID DE LA VARIABLE MAIN QUE ES TIPO DE RECURSO AWS_VPC
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}