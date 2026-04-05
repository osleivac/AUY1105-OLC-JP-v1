# ─────────────────────────────────────────────────────────────
# ec2.tf  –  Todo lo necesario para crear la EC2
#
# Este archivo es AUTOSUFICIENTE junto a provider.tf y vpc.tf.
# No requiere variables.tf ni outputs.tf.
#
# Variables internalizadas aqui:
#   - instance_type  → local (t2.micro, requerido por politica OPA)
#   - public_key     → variable declarada aqui, inyectada via
#                      Secret TF_VAR_public_key en GitHub Actions
# Outputs declarados al final de este archivo.
# ─────────────────────────────────────────────────────────────

# ── Variables (antes en variables.tf) ────────────────────────

variable "instance_type" {
  description = "Tipo de instancia EC2. Politica OPA restringe a t2.micro unicamente."
  type        = string
  default     = "t2.micro"
}

# La clave publica SSH se inyecta via Secret de GitHub Actions:
#   Secret name: TF_VAR_public_key
#   Valor:       contenido de ~/.ssh/auy1105_key.pub
# Nunca se hardcodea en el repositorio.
variable "public_key" {
  description = "Clave publica SSH para acceso a la EC2 (Secret: TF_VAR_public_key)"
  type        = string
  sensitive   = true
}

# ── Key Pair ─────────────────────────────────────────────────
resource "aws_key_pair" "AUY1105-tiendatech-key" {
  key_name   = "AUY1105-tiendatech-key"
  public_key = var.public_key
  tags       = { Name = "AUY1105-tiendatech-key" }
}

# ── Security Group ───────────────────────────────────────────
# Ingress SSH 0.0.0.0/0 justificado:
#   Los runners de GitHub Actions usan IPs dinamicas sin rango
#   fijo, por lo que no es posible restringir por CIDR especifico.
#   Esta excepcion esta documentada en el informe tecnico.
resource "aws_security_group" "AUY1105-tiendatech-sg" {
  name        = "AUY1105-tiendatech-sg"
  description = "SSH para GitHub Actions runners + salida internet para user_data"
  vpc_id      = aws_vpc.AUY1105-tiendatech-vpc.id

  ingress {
    description = "SSH desde GitHub Actions runners (IPs dinamicas - excepcion justificada)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida total requerida para que user_data (install.sh) pueda
  # descargar: apt packages, Terraform, TFLint, Checkov, OPA, terraform-docs
  egress {
    description = "Salida total (user_data necesita acceso a internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "AUY1105-tiendatech-sg" }
}

# ── AMI: Ubuntu 24.04 LTS ────────────────────────────────────
# Owner 099720109477 = Canonical (cuenta oficial en AWS)
# Requerido por rubrica: Ubuntu 24.04 LTS
data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Instancia EC2 ─────────────────────────────────────────────
resource "aws_instance" "AUY1105-tiendatech-ec2" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.AUY1105-tiendatech-subnet-pub-1.id
  vpc_security_group_ids      = [aws_security_group.AUY1105-tiendatech-sg.id]
  key_name                    = aws_key_pair.AUY1105-tiendatech-key.key_name
  associate_public_ip_address = true  # IP publica para acceso SSH desde GitHub Actions

  # install.sh se ejecuta automaticamente en el primer boot de la instancia.
  # Ubuntu 24.04 usa el usuario "ubuntu", no "ec2-user".
  user_data = filebase64("${path.module}/install.sh")

  # IMDSv2 obligatorio → resuelve Checkov CKV_AWS_79
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true   # Checkov CKV_AWS_8
    volume_type = "gp3"  # Mejor performance que gp2, mismo precio Free Tier
    volume_size = 8      # 8 GB: suficiente para las herramientas, dentro del limite Free Tier (30 GB)
  }

  # ebs_optimized NO se incluye: t2.micro no soporta esta opcion
  # y genera error en terraform apply dentro del Free Tier.

  tags = { Name = "AUY1105-tiendatech-ec2" }
}

# ── Outputs (antes en outputs.tf) ────────────────────────────

output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.AUY1105-tiendatech-ec2.id
}

output "public_ip" {
  description = "IP publica de la EC2 (usada por GitHub Actions para conectar via SSH)"
  value       = aws_instance.AUY1105-tiendatech-ec2.public_ip
}

output "key_pair_name" {
  description = "Nombre del Key Pair creado en AWS"
  value       = aws_key_pair.AUY1105-tiendatech-key.key_name
}
