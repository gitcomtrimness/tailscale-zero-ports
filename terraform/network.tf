# Dedicated network. Outbound internet only; the firewall allows NO inbound traffic.
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "meridian-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "meridian-igw" }
}

resource "aws_subnet" "prod" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags                    = { Name = "meridian-prod" }
}

resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "meridian-prod-rt" }
}

resource "aws_route_table_association" "prod" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.prod.id
}

# The point of the demo: no ingress rules at all. Outbound only.
resource "aws_security_group" "prod" {
  name        = "meridian-prod-no-inbound"
  description = "No inbound traffic. Access is only via Tailscale."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "meridian-prod-no-inbound" }
}