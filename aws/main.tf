data "aws_availability_zones" "zones" {}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "pub_subnet" {
  count             = length(var.pub_cidr_block)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.pub_cidr_block[count.index]
  availability_zone = element(data.aws_availability_zones.zones.names, count.index)
  tags = {
    Name = "pub_subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_cidr_block)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_block[count.index]
  availability_zone = element(data.aws_availability_zones.zones.names, count.index)
  tags = {
    Name = "pri_subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id     = aws_eip.eip.id
  subnet_id         = aws_subnet.pub_subnet[0].id
  connectivity_type = "public"
  tags = {
    Name = "nat"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public_association" {
  count          = length(var.pub_cidr_block)
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "private_association" {
  count          = length(var.private_cidr_block)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.nat_route.id
}

resource "aws_network_acl" "nacl" {
  count = var.enable_nacl ? 1 : 0
  vpc_id = aws_vpc.main.id
  egress {
    from_port  = "0"
    to_port    = "0"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = "100"
  }
  ingress {
    from_port  = "0"
    to_port    = "0"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    rule_no    = "100"
  }
  tags = {
    Name = "nacl"
  }
}

resource "aws_network_acl_association" "pub_nacl_association" {
  count          = var.enable_nacl ? length(var.pub_cidr_block) : 0
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  network_acl_id = aws_network_acl.nacl[0].id
}

resource "aws_network_acl_association" "private_nacl_association" {
  count          = var.enable_nacl ? length(var.private_cidr_block) : 0
  subnet_id      = aws_subnet.private_subnet[count.index].id
  network_acl_id = aws_network_acl.nacl[0].id
}