variable "instance_type" {
  description = "Tipo de instancia EC2 (solo se permite t2.micro por política OPA)"
  type        = string
  default     = "t2.micro"
}


variable "app_name" {
  description = "Nombre de la aplicación para nomenclatura de recursos"
  type        = string
  default     = "tiendatech"
}
