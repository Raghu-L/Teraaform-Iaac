output "elastic_IP" {
    value = aws_eip.lb.id
  
}