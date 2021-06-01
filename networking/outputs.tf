#---outputs/networking-module---

output ec2logs_ids {
  description = "IDs of Linux instances"
  value       = aws_instance.logs.*.id
}