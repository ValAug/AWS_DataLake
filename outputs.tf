#---outputs/root---

output "ec2_info" {
  description = "EC2s information"
  value = [for x in module.network[*]: x]
}

output "stream_info" {
  description = "Data flow information"
  value = [for x in module.data[*]: x]
}