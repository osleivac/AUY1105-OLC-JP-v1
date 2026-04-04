resource "aws_security_group" "AUY1105-tiendatech-sg" {
  name        = "AUY1105-tiendatech-sg"
  description = "Permitir SSH restringido (no publico)"
  vpc_id      = aws_vpc.AUY1105-tiendatech-vpc.id


  ingress {
    description = "SSH restringido (politica OPA: no 0.0.0.0/0)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]   # Solo trafico interno VPC
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = { Name = "AUY1105-tiendatech-sg" }
}


# AMI Ubuntu 24.04 LTS (requerido por rubrica)
data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}


resource "aws_instance" "AUY1105-tiendatech-ec2" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = var.instance_type   # t2.micro (politica OPA)
  subnet_id              = aws_subnet.AUY1105-tiendatech-subnet-pub-1.id
  vpc_security_group_ids = [aws_security_group.AUY1105-tiendatech-sg.id]


  root_block_device {
    encrypted = true   # Requerido por Checkov
  }


  tags = { Name = "AUY1105-tiendatech-ec2" }
}
