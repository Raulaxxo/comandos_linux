#!/bin/bash
# =========================================================
# Script: setup-bonding-lacp.sh
# Uso:
#   ./setup-bonding-lacp.sh bond0 ens160,ens192 static 172.16.5.210/24 172.16.5.1 8.8.8.8
#   ./setup-bonding-lacp.sh bond0 ens160,ens192 dhcp
# =========================================================

# -------------------------------
# VALIDAR PARÁMETROS
# -------------------------------
if [[ $# -lt 4 ]]; then
  echo "Uso:"
  echo "  $0 <bond_name> <iface1,iface2> <static|dhcp> [ip/mask] [gateway] [dns]"
  echo
  echo "Ejemplo IP estática:"
  echo "  $0 bond0 ens160,ens192 static 172.16.5.210/24 172.16.5.1 8.8.8.8"
  echo
  echo "Ejemplo DHCP:"
  echo "  $0 bond0 ens160,ens192 dhcp"
  exit 1
fi

# -------------------------------
# PARÁMETROS
# -------------------------------
BOND_NAME="$1"
IFS=',' read -ra SLAVES <<< "$2"
IP_METHOD="$3"
IP_ADDRESS="$4"
GATEWAY="$5"
DNS="$6"

# -------------------------------
# VALIDACIONES
# -------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "❌ Ejecutar como root"
  exit 1
fi

command -v nmcli >/dev/null 2>&1 || {
  echo "❌ nmcli no está instalado"
  exit 1
}

if [[ "$IP_METHOD" == "static" && ( -z "$IP_ADDRESS" || -z "$GATEWAY" || -z "$DNS" ) ]]; then
  echo "❌ Para IP estática debes indicar: ip/mask gateway dns"
  exit 1
fi

echo "✅ Parámetros válidos"

# -------------------------------
# LIMPIEZA PREVIA
# -------------------------------
echo "🧹 Eliminando configuraciones previas..."

nmcli -t -f NAME con show | grep -E "^${BOND_NAME}$|^${BOND_NAME}-slave" | while read -r con; do
  nmcli con delete "$con"
done

# -------------------------------
# CREAR BOND
# -------------------------------
echo "🔧 Creando bond $BOND_NAME..."

nmcli con add type bond \
  ifname "$BOND_NAME" \
  con-name "$BOND_NAME" \
  bond.options "mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer3+4"

# -------------------------------
# CONFIGURAR IP
# -------------------------------
if [[ "$IP_METHOD" == "static" ]]; then
  echo "🌐 Configurando IP estática..."
  nmcli con modify "$BOND_NAME" \
    ipv4.method manual \
    ipv4.addresses "$IP_ADDRESS" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "$DNS"
else
  echo "🌐 Configurando IP por DHCP..."
  nmcli con modify "$BOND_NAME" ipv4.method auto
fi

# -------------------------------
# CREAR SLAVES
# -------------------------------
echo "🔗 Agregando interfaces esclavas..."

for IFACE in "${SLAVES[@]}"; do
  nmcli con add type ethernet \
    ifname "$IFACE" \
    con-name "${BOND_NAME}-slave-${IFACE}" \
    master "$BOND_NAME"
done

# -------------------------------
# LEVANTAR CONEXIONES
# -------------------------------
echo "🚀 Activando bonding..."

nmcli con up "$BOND_NAME"

for IFACE in "${SLAVES[@]}"; do
  nmcli con up "${BOND_NAME}-slave-${IFACE}"
done

# -------------------------------
# VERIFICACIÓN
# -------------------------------
echo "📊 Estado final:"
nmcli device status

echo "📄 Detalle del bond:"
cat /proc/net/bonding/$BOND_NAME || echo "⚠️ Bond aún no disponible"

echo "✅ Bonding LACP configurado correctamente"
