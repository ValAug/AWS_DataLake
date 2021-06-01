#---analytic-root---

resource "aws_s3_bucket" "data_logs" {
  bucket = var.bucket_name

}

resource "aws_iam_role" "f_role" {
  name = "f_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "f_delivery_policy" { 
  role = aws_iam_role.f_role.id

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.data_logs.arn}"
    }
  ]

}
EOT
}

resource "aws_kinesis_firehose_delivery_stream" "datalogs_stream" {  
  name        = "datalogsstream"
  destination = "s3"

  s3_configuration { 
    role_arn        = aws_iam_role.f_role.arn
    bucket_arn      = aws_s3_bucket.data_logs.arn
    buffer_size     = 5
    buffer_interval = 60
  }
}