terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Las credenciales se inyectan via variables de entorno (Secrets de GitHub Actions):
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_SESSION_TOKEN
# No se deben hardcodear aqui nunca.
provider "aws" {
  region = "us-east-1"
}
