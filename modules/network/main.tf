resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "eks-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

# Public and private subnets
resource "aws_subnet" "public" {
  for_each                = zipmap(var.azs, var.public_cidrs)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    {
      Name                               = "public-${each.key}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    }
)
}

resource "aws_subnet" "private" {
  for_each          = zipmap(var.azs, var.private_cidrs)
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge(
    var.tags,
    {
      Name                               = "private-${each.key}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    }
)
}

# Routing for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT per‑AZ and private route tables
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = var.tags
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = var.tags
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  tags     = var.tags
}

resource "aws_route" "private_egress" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each             = var.ssm_endpoints

  vpc_id               = aws_vpc.this.id
  service_name         = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type    = "Interface"
  private_dns_enabled  = true
  subnet_ids           = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids   = [var.security_group_ids]
  tags = {
    Name = "EKS-task-${each.key}"
  }
  depends_on = [ aws_subnet.private ]
}
