resource "aws_iam_role" "metabase_s3_output_role" {
  name = "metabase-s3-output-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "metabase_s3_output_policy" {
  name        = "metabase-s3-output-policy"
  description = "Allow Metabase to write exports to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.metabase_exports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.metabase_exports.arn
        ]
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "metabase_s3_output_attach" {
  role       = aws_iam_role.metabase_s3_output_role.name
  policy_arn = aws_iam_policy.metabase_s3_output_policy.arn
}

resource "aws_iam_instance_profile" "metabase_s3_output_profile" {
  name = "metabase-s3-output-profile"
  role = aws_iam_role.metabase_s3_output_role.name
}

