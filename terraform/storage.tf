#1 rds instance with 2 dbs on it
resource "aws_db_instance" "metabase_db" {
  identifier            = "metabase-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp2"
  username              = var.db_username
  password              = var.db_password
  publicly_accessible   = false
  skip_final_snapshot   = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.metabase_subnet_group.name
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