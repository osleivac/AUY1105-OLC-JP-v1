#!/bin/bash
# ─────────────────────────────────────────────────────────────
# install.sh  –  Aprovisionamiento EC2 Ubuntu 24.04 LTS
# Ejecutado via user_data al primer arranque de la instancia
#
# AUDITORIA:
#   - CORREGIDO: usaba "yum" pero la AMI es Ubuntu → debe usar "apt"
#   - AGREGADO: TFLint (faltaba en el script original)
#   - CORREGIDO: orden de dependencias (unzip y curl antes que las herramientas)
#   - CORREGIDO: OPA URL correcta (faltaba sufijo _static para Linux)
#   - AGREGADO: log a /var/log/install.log para depuración via SSH
# ─────────────────────────────────────────────────────────────

set -euo pipefail
LOG="/var/log/install.log"
exec > >(tee -a "$LOG") 2>&1

echo "=============================="
echo "Inicio de aprovisionamiento EC2"
echo "Fecha: $(date)"
echo "=============================="

# ── Función de manejo de errores ──────────────────────────────
handle_error() {
  echo "ERROR: Fallo en el paso $1. Revisa $LOG"
  exit 1
}

# ── PASO 1: Actualizar sistema e instalar dependencias base ───
# CORREGIDO: era "yum" – Ubuntu usa "apt"
echo "[1/7] Actualizando sistema e instalando dependencias..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y                                          || handle_error "1.1 (apt-get update)"
apt-get install -y \
  curl \
  unzip \
  python3 \
  python3-pip \
  python3-venv \
  git \
  jq                                                       || handle_error "1.2 (apt-get install dependencias)"

# ── PASO 2: Instalar Terraform ────────────────────────────────
echo "[2/7] Instalando Terraform..."
apt-get install -y gnupg software-properties-common       || handle_error "2.1 (gnupg)"
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
                                                           || handle_error "2.2 (GPG HashiCorp)"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/hashicorp.list             || handle_error "2.3 (repo HashiCorp)"
apt-get update -y                                          || handle_error "2.4 (apt update post-repo)"
apt-get install -y terraform                               || handle_error "2.5 (terraform install)"
terraform version

# ── PASO 3: Instalar TFLint ───────────────────────────────────
# AGREGADO: faltaba en el script original
echo "[3/7] Instalando TFLint..."
TFLINT_VERSION="v0.50.3"
curl -sSL \
  "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip" \
  -o /tmp/tflint.zip                                       || handle_error "3.1 (descarga TFLint)"
unzip -o /tmp/tflint.zip -d /tmp/tflint-bin               || handle_error "3.2 (unzip TFLint)"
mv /tmp/tflint-bin/tflint /usr/local/bin/tflint           || handle_error "3.3 (instalar TFLint)"
chmod +x /usr/local/bin/tflint
rm -rf /tmp/tflint.zip /tmp/tflint-bin
tflint --version

# ── PASO 4: Instalar Checkov ──────────────────────────────────
echo "[4/7] Instalando Checkov..."
# Usar entorno virtual para evitar conflictos con paquetes del sistema (PEP 668)
python3 -m venv /opt/checkov-venv                         || handle_error "4.1 (crear venv)"
/opt/checkov-venv/bin/pip install --upgrade pip           || handle_error "4.2 (upgrade pip)"
/opt/checkov-venv/bin/pip install checkov                 || handle_error "4.3 (pip install checkov)"
# Symlink para usar como comando global
ln -sf /opt/checkov-venv/bin/checkov /usr/local/bin/checkov
checkov --version

# ── PASO 5: Instalar Terraform-Docs ──────────────────────────
echo "[5/7] Instalando Terraform-Docs..."
TFDOCS_VERSION="v0.19.0"
curl -sSLo /tmp/terraform-docs.tar.gz \
  "https://terraform-docs.io/dl/${TFDOCS_VERSION}/terraform-docs-${TFDOCS_VERSION}-linux-amd64.tar.gz" \
                                                           || handle_error "5.1 (descarga terraform-docs)"
tar -xzf /tmp/terraform-docs.tar.gz -C /tmp/             || handle_error "5.2 (extraer terraform-docs)"
mv /tmp/terraform-docs /usr/local/bin/terraform-docs      || handle_error "5.3 (instalar terraform-docs)"
chmod +x /usr/local/bin/terraform-docs
rm -f /tmp/terraform-docs.tar.gz
terraform-docs --version

# ── PASO 6: Instalar OPA ──────────────────────────────────────
echo "[6/7] Instalando OPA..."
# CORREGIDO: URL original usaba opa_linux_amd64 sin sufijo _static
# El binario _static es el recomendado para entornos sin libc especifica
curl -sSL \
  "https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static" \
  -o /usr/local/bin/opa                                   || handle_error "6.1 (descarga OPA)"
chmod +x /usr/local/bin/opa
opa version

# ── PASO 7: Verificación final ────────────────────────────────
echo "[7/7] Verificacion de herramientas instaladas..."
echo "---"
terraform   version | head -1
tflint      --version
checkov     --version | head -1
terraform-docs --version
opa         version | head -1
echo "---"

echo "=============================="
echo "Aprovisionamiento COMPLETADO"
echo "Fecha: $(date)"
echo "=============================="
