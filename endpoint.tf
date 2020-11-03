resource "aws_security_group" "epsg" {
  name        = "${var.cluster_name}-epsg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = {
    Name = "${var.cluster_name}-epsg"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_id
}

resource "aws_vpc_endpoint" "ecrapi" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [aws_security_group.epsg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecrdocker" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [aws_security_group.epsg.id]
  subnet_ids          = flatten([var.private_subnet])
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [aws_security_group.epsg.id]
  subnet_ids          = flatten([var.private_subnet])
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "CWLogsEndpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.epsg.id]
  subnet_ids          = flatten([var.private_subnet])
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [aws_security_group.epsg.id]
  subnet_ids          = flatten([var.private_subnet])
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "autoscaling" {
   vpc_id              = var.vpc_id
   service_name        = "com.amazonaws.${var.region}.autoscaling"
   vpc_endpoint_type   = "Interface"
   security_group_ids = [aws_security_group.epsg.id]
   subnet_ids          = flatten([var.private_subnet])
   private_dns_enabled = true
}

resource "aws_vpc_endpoint" "appmesh-envoy-management" {
   vpc_id              = var.vpc_id
   service_name        = "com.amazonaws.${var.region}.appmesh-envoy-management"
   vpc_endpoint_type   = "Interface"
   security_group_ids = [aws_security_group.epsg.id]
   subnet_ids          = flatten([var.private_subnet])
   private_dns_enabled = true
}
