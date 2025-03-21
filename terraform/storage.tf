resource "aws_ebs_volume" "metabase_storage" {
  availability_zone = aws_instance.data_board.availability_zone
  size              = 5 #GB
  type              = "gp3"
}

resource "aws_volume_attachment" "metabase_storage_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.metabase_storage.id
  instance_id = aws_instance.data_board.id
}

resource "aws_s3_bucket" "metabase_exports" {
  bucket = "metabase-exports-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = "metabase-exports-${data.aws_caller_identity.current.account_id}"

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = "metabase-exports-${data.aws_caller_identity.current.account_id}"
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = "metabase-exports-${data.aws_caller_identity.current.account_id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}