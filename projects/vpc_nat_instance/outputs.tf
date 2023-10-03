output "vpc_nat_instance" {
  value = merge(
    module.nat_instance, {
      eip_public_ip = aws_eip.nat_instance.public_ip,
    }
  )
}
