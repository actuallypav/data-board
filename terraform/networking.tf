data "aws_route53_zone" "domain" {
  name = var.domain_name
}

resource "aws_route53_record" "metabase_dns" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "metabase" #metabase.pavest.click
  type    = "A"
  ttl     = 300
  records = [aws_instance.data_board.public_ip]
}

#security group
resource "aws_security_group" "allow_metabase" {
  name        = "allow_tls"
  description = "Allow SSH(not currently), HTTP, HTTPS for Metabase"
  vpc_id      = aws_vpc.main_data.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_metabase.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_metabase.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

#all outbound traffic (for metabase reqs)
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.allow_metabase.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

# #ONLY FOR DEBUGGING
# resource "aws_vpc_security_group_ingress_rule" "allow_metabas_ui" {
#   security_group_id = aws_security_group.allow_metabase.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 3000
#   ip_protocol       = "tcp"
#   to_port           = 3000
# }


# resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#   security_group_id = aws_security_group.allow_metabase.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }