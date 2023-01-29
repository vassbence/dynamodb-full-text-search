resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/21"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "route_table_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet_public.id
}

resource "aws_default_network_acl" "default_network_acl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  subnet_ids             = [aws_subnet.subnet_public.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_default_security_group" "default_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.eu-central-1.dynamodb"
  route_table_ids = [aws_route_table.route_table_public.id]
}
