resource "aws_vpc" "AUY1105-tiendatech-vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "AUY1105-tiendatech-vpc" }
}


resource "aws_internet_gateway" "AUY1105-tiendatech-igw" {
  vpc_id = aws_vpc.AUY1105-tiendatech-vpc.id
  tags   = { Name = "AUY1105-tiendatech-igw" }
}


resource "aws_subnet" "AUY1105-tiendatech-subnet-pub-1" {
  vpc_id                  = aws_vpc.AUY1105-tiendatech-vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "AUY1105-tiendatech-subnet-pub-1" }
}
resource "aws_subnet" "AUY1105-tiendatech-subnet-priv-1" {
  vpc_id            = aws_vpc.AUY1105-tiendatech-vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "AUY1105-tiendatech-subnet-priv-1" }
}


resource "aws_route_table" "AUY1105-tiendatech-rt-pub" {
  vpc_id = aws_vpc.AUY1105-tiendatech-vpc.id
  tags   = { Name = "AUY1105-tiendatech-rt-pub" }
}


resource "aws_route" "AUY1105-tiendatech-route-internet" {
  route_table_id         = aws_route_table.AUY1105-tiendatech-rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.AUY1105-tiendatech-igw.id
}


resource "aws_route_table_association" "AUY1105-tiendatech-rta-pub" {
  subnet_id      = aws_subnet.AUY1105-tiendatech-subnet-pub-1.id
  route_table_id = aws_route_table.AUY1105-tiendatech-rt-pub.id
}
