Manual: Configuración de Bonding LACP (802.3ad) en Red Hat Linux
1️⃣ Requisitos previos
En el sistema

Red Hat Enterprise Linux 8 o 9

Acceso root o sudo

NetworkManager habilitado

Verifica:

systemctl status NetworkManager

En el switch

Los puertos deben estar configurados en LACP activo

Ambos puertos en el mismo port-channel / agregación

Mismo VLAN / trunk / access en ambos

⚠️ Si el switch no tiene LACP configurado, la red no levantará.

2️⃣ Identificar interfaces físicas

Lista las interfaces disponibles:

nmcli device status


Ejemplo:

DEVICE   TYPE      STATE      CONNECTION
ens160   ethernet  connected  --
ens192   ethernet  connected  --


En este ejemplo:

ens160

ens192

3️⃣ Crear el bonding (bond0)

Crear la interfaz bond con LACP:

nmcli connection add type bond \
  ifname bond0 \
  con-name bond0 \
  bond.options "mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer3+4"

📌 Parámetros clave
Parámetro	Descripción
mode=802.3ad	LACP
miimon=100	Chequeo de enlace cada 100 ms
lacp_rate=fast	Envío rápido de LACP
xmit_hash_policy=layer3+4	Mejor balanceo (IP + puerto)
4️⃣ Asignar IP al bond
IP estática
nmcli connection modify bond0 \
  ipv4.method manual \
  ipv4.addresses 172.16.5.210/24 \
  ipv4.gateway 172.16.5.1 \
  ipv4.dns 8.8.8.8

O DHCP
nmcli connection modify bond0 ipv4.method auto

5️⃣ Agregar las interfaces esclavas

Agregar la primera interfaz:

nmcli connection add type ethernet \
  ifname ens160 \
  con-name bond0-slave-ens160 \
  master bond0


Agregar la segunda interfaz:

nmcli connection add type ethernet \
  ifname ens192 \
  con-name bond0-slave-ens192 \
  master bond0

6️⃣ Levantar el bonding
nmcli connection up bond0
nmcli connection up bond0-slave-ens160
nmcli connection up bond0-slave-ens192


Verifica:

nmcli device status


Debe verse algo así:

bond0    bond      connected
ens160   ethernet  connected (slave)
ens192   ethernet  connected (slave)

7️⃣ Verificación del estado LACP
Ver estado del bond
cat /proc/net/bonding/bond0


Salida esperada:

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
MII Status: up
LACP rate: fast
Slave Interface: ens160
  MII Status: up
Slave Interface: ens192
  MII Status: up

8️⃣ Pruebas recomendadas
Prueba de conectividad
ping -c 5 172.16.5.1

Prueba de alta disponibilidad

Desconecta un cable

El ping no debe cortarse

Reconecta y valida que vuelva al bond

9️⃣ Archivos de configuración (referencia)

NetworkManager guarda en:

/etc/NetworkManager/system-connections/


Ejemplo:

bond0.nmconnection

bond0-slave-ens160.nmconnection

bond0-slave-ens192.nmconnection

🔥 Problemas comunes
❌ El bond queda DOWN

LACP no configurado en el switch

Puertos en VLAN distinta

Un puerto en speed/duplex diferente

❌ Solo un slave activo

Revisa configuración del port-channel

Verifica cat /proc/net/bonding/bond0

🧠 Buenas prácticas

✔ Siempre configurar primero el switch
✔ Usar layer3+4 para servidores
✔ Documentar qué puertos físicos están agregados
✔ Probar failover antes de pasar a producción
