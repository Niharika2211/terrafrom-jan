resource "aws_vpc" "new" {
  cidr_block           = var.vpc_cidr_rng
  instance_tenancy     = "default"
  enable_dns_support   = var.enable_dns_hostnames
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.new.id

  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )

}

resource "aws_subnet" "pub-sub" {
  count                   = length(var.pub_sub_cidr)
  vpc_id                  = aws_vpc.new.id
  cidr_block              = var.pub_sub_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${local.name}-public-${split("-", var.azs[count.index])[2]}"
    },
    var.common_tags
  )
}

resource "aws_subnet" "pvt-sub" {
  count             = length(var.pvt_sub_cidr)
  vpc_id            = aws_vpc.new.id
  cidr_block        = var.pvt_sub_cidr[count.index]
  availability_zone = var.azs[count.index]


  tags = merge(
    {
      Name = "${local.name}-pvt-${split("-", var.azs[count.index])[2]}"
    },
    var.common_tags
  )
}

resource "aws_subnet" "db-sub" {
  count             = length(var.db_sub_cidr)
  vpc_id            = aws_vpc.new.id
  cidr_block        = var.db_sub_cidr[count.index]
  availability_zone = var.azs[count.index]
  tags = merge(
    {
      Name = "${local.name}-db-${split("-", var.azs[count.index])[2]}"
    },
    var.common_tags
  )
}


resource "aws_route_table" "new_route_table" {
  vpc_id = aws_vpc.new.id

  tags = merge(
    {
      Name = "${local.name}-new-route-table"
    },
    var.common_tags
  )
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.new.id
  tags = merge(
    {
      Name = "${local.name}-public-rt"
    },
    var.common_tags
  )
}

resource "aws_route_table" "private-RT" {
  vpc_id = aws_vpc.new.id
  tags = merge(
    {
      Name = "${local.name}-pvt-rt"
    },
    var.common_tags
  )
}


resource "aws_route_table" "db-RT" {
  vpc_id = aws_vpc.new.id
  tags = merge(
    {
      Name = "${local.name}-db-rt"
    },
    var.common_tags
  )
}


resource "aws_route_table_association" "pub_rta" {
  count          = length(aws_subnet.pub-sub)
  subnet_id      = aws_subnet.pub-sub[count.index].id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "pvt_rta" {
  count          = length(aws_subnet.pvt-sub)
  subnet_id      = aws_subnet.pvt-sub[count.index].id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "db_rta" {
  count          = length(aws_subnet.db-sub)
  subnet_id      = aws_subnet.db-sub[count.index].id
  route_table_id = aws_route_table.db-RT.id
}


resource "aws_eip" "mip" {
  count  = var.nat_enable ? 1 : 0
  domain = "vpc"
  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

resource "aws_nat_gateway" "mini_nat" {
  count         = var.nat_enable ? 1 : 0
  allocation_id = aws_eip.mip[count.index].id
  subnet_id     = aws_subnet.pub-sub[0].id

  tags = merge({
    Name = local.name
    },
  var.common_tags)

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route" "public" {
  route_table_id         = aws_route_table.RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private" {
  count                  = var.nat_enable ? 1 : 0
  route_table_id         = aws_route_table.private-RT.id
  destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id           = aws_nat_gateway.mini_nat[count.index].id
}

resource "aws_route" "db" {
  count                  = var.nat_enable ? 1 : 0
  route_table_id         = aws_route_table.db-RT.id
  destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id            = aws_nat_gateway.mini_nat[count.index].id
}

resource "aws_vpc_peering_connection" "foo-peer" {
  peer_vpc_id = data.aws_vpc.selected.id
  auto_accept = "true"
  vpc_id      = aws_vpc.new.id

  tags = merge(
    {
      Name = local.name
    },
    var.common_tags
  )
}

resource "aws_route" "pub_route" {
  route_table_id            = aws_route_table.RT.id
  destination_cidr_block    = data.aws_vpc.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo-peer.id
}


resource "aws_route" "pvt_route" {
  route_table_id            = aws_route_table.private-RT.id
  destination_cidr_block    = data.aws_vpc.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo-peer.id
}


resource "aws_route" "db_route" {
  route_table_id            = aws_route_table.db-RT.id
  destination_cidr_block    = data.aws_vpc.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo-peer.id
}

resource "aws_route" "default_route" {
  route_table_id            = aws_route_table.new_route_table.id
  destination_cidr_block    = aws_vpc.new.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo-peer.id
}
