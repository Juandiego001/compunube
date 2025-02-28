#!/bin/bash

# Actualizar Ubuntu
# export DEBIAN_FRONTEND=noninteractive
# apt-get update

# Descomentar para hacer Upgrade
# apt-get -o Dpkg::Options::="--force-confold" upgrade -q -y --force-yes &&
# apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -q -y --force-yes

# Actualización de Snap
# snap refresh

# Verificar instalación de lxd
snap version

# Verificar que el usuario vagrant esté en lxd
sudo getent group lxd | grep "$USER"

# Inicialización de lxd
echo "Inicialización de lxd..."
lxd init --minimal

# Habilitación para acceder a la UI
echo "Habilitación para acceder a la UI..."
lxc config set core.https_address 192.168.100.3:8443

# Regla IP Tables para redireccionar
iptables -t nat -A PREROUTING -p udp --dport 8000 -j DNAT --to-destination 10.20.80.2:8000
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT