data "aws_route53_zone" "domain" {
  name = var.domain_name
}

resource "aws_route53_record" "grafana_dns" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "dash.${var.domain_name}" #data.${domain}
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.grafana_server.public_ip
  ]

  depends_on = [aws_instance.grafana_server]
}

#security group
resource "aws_security_group" "allow_grafana" {
  name        = "allow_tls"
  description = "Allow SSH(not currently), HTTP, HTTPS for Grafana"
  vpc_id      = aws_vpc.main_data.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

#all outbound traffic (for grafana reqs)
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.allow_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_subnet" "private_db_a" {
  vpc_id                  = aws_vpc.main_data.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_db_b" {
  vpc_id                  = aws_vpc.main_data.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_data.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "grafana_gw" {
  vpc_id = aws_vpc.main_data.id
}

resource "aws_route_table" "grafana_route" {
  vpc_id = aws_vpc.main_data.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grafana_gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.grafana_route.id
}

resource "aws_db_subnet_group" "grafana_subnet_group" {
  name = "grafana-subnet-group"
  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id
  ]
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL access from Grafana EC2"
  vpc_id      = aws_vpc.main_data.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      aws_security_group.allow_grafana.id,
      aws_security_group.lambda_sg.id
    ]
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Allow lambda to access RDS"
  vpc_id      = aws_vpc.main_data.id

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# #ONLY FOR DEBUGqGING
# resource "aws_vpc_security_group_ingress_rule" "allow_metabas_ui" {
#   security_group_id = aws_security_group.allow_grafana.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 3000
#   ip_protocol       = "tcp"
#   to_port           = 3000
# }


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}