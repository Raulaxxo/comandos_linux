 📘 Manual: Configuración de Bonding LACP (802.3ad) en Red Hat Enterprise Linux

## Paso 1: Verificar requisitos previos

### Sistema
- Red Hat Enterprise Linux 8 o 9
- Acceso root o sudo
- NetworkManager habilitado

```bash
systemctl status NetworkManager
```

### Switch
- LACP habilitado (modo active)
- Puertos en el mismo port-channel
- Misma VLAN / trunk / access
- Speed y duplex iguales

---

## Paso 2: Identificar interfaces de red

```bash
nmcli device status
```

Ejemplo:
```
DEVICE   TYPE      STATE      CONNECTION
ens160   ethernet  connected
ens192   ethernet  connected
```

---

## Paso 3: Crear la interfaz bonding (bond0)

```bash
nmcli connection add type bond \
  ifname bond0 \
  con-name bond0 \
  bond.options "mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer3+4"
```

---

## Paso 4: Configurar dirección IP del bond

```bash
nmcli connection modify bond0 \
  ipv4.method manual \
  ipv4.addresses 172.16.5.210/24 \
  ipv4.gateway 172.16.5.1 \
  ipv4.dns 8.8.8.8
```

---

## Paso 5: Agregar interfaces esclavas

```bash
nmcli connection add type ethernet \
  ifname ens160 \
  con-name bond0-slave-ens160 \
  master bond0
```

```bash
nmcli connection add type ethernet \
  ifname ens192 \
  con-name bond0-slave-ens192 \
  master bond0
```

---

## Paso 6: Activar el bonding

```bash
nmcli connection up bond0
nmcli connection up bond0-slave-ens160
nmcli connection up bond0-slave-ens192
```

---

## Paso 7: Verificar estado

```bash
nmcli device status
cat /proc/net/bonding/bond0
```

---

## Paso 8: Probar conectividad

```bash
ping -c 5 172.16.5.1
```

---

## Paso 9: Probar alta disponibilidad

1. Desconectar un cable
2. Verificar que no se pierde conectividad
3. Reconectar el cable

---

## Paso 10: Archivos de configuración

```bash
/etc/NetworkManager/system-connections/
```

- bond0.nmconnection
- bond0-slave-ens160.nmconnection
- bond0-slave-ens192.nmconnection

