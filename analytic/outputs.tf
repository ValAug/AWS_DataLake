#---outputs/analytics-module---

output kinesis_stream_name {
  description = "stream-info"
  value       = aws_kinesis_firehose_delivery_stream.datalogs_stream.*.name
}