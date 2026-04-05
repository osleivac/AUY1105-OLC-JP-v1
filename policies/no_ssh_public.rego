package terraform.authz

# ─────────────────────────────────────────────────────────────
# Politica 1: Bloquear acceso SSH publico (0.0.0.0/0)
# Criterio: IL 6.2.1 / IL 6.2.3
#
# NOTA DE EXCEPCION DOCUMENTADA:
#   El Security Group AUY1105-tiendatech-sg permite 0.0.0.0/0
#   en el puerto 22 por requerimiento operacional: los runners
#   de GitHub Actions usan IPs dinamicas sin rango CIDR fijo.
#   Esta excepcion esta documentada en el informe tecnico del proyecto.
#   La politica detecta y reporta la condicion; el equipo la revisa
#   y aprueba como excepcion controlada en cada PR.
# ─────────────────────────────────────────────────────────────

default allow = false

# Permite si NO hay SSH publico abierto
allow {
  not ssh_public_access
}

# Detecta si algun security group tiene SSH (puerto 22) abierto a 0.0.0.0/0
ssh_public_access {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
}

# Genera mensaje de violacion detallado
violation[msg] {
  sg := input.resource_changes[_]
  sg.type == "aws_security_group"
  ingress := sg.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf(
    "VIOLACION: Security Group '%v' permite SSH (puerto 22) desde 0.0.0.0/0. EXCEPCION APROBADA: requerido para GitHub Actions runners (IPs dinamicas).",
    [sg.address]
  )
}
