package terraform.authz

# ─────────────────────────────────────────────────────────────
# Politica 2: Solo permitir instancias EC2 de tipo t2.micro
# Criterio: IL 6.2.1 / IL 6.2.3
#
# Justificacion: control de costos en AWS Academy Learner Labs
# y cumplimiento con Free Tier. Cualquier tipo distinto a
# t2.micro debe ser rechazado antes del despliegue.
# ─────────────────────────────────────────────────────────────

default allow_instance_type = false

# Permite si NO hay instancias con tipo invalido
allow_instance_type {
  not invalid_instance_type
}

# Detecta si alguna EC2 usa un tipo distinto a t2.micro
invalid_instance_type {
  ec2 := input.resource_changes[_]
  ec2.type == "aws_instance"
  ec2.change.after.instance_type != "t2.micro"
}

# Genera mensaje de violacion detallado
violation[msg] {
  ec2 := input.resource_changes[_]
  ec2.type == "aws_instance"
  ec2.change.after.instance_type != "t2.micro"
  msg := sprintf(
    "VIOLACION: Instancia EC2 '%v' usa tipo '%v'. Solo se permite 't2.micro' por politica de costos y Free Tier.",
    [ec2.address, ec2.change.after.instance_type]
  )
}
