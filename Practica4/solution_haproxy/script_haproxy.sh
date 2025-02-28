#!/bin/bash

# Script de configuración de haproxy

# Actualización de paquetes e instalación de apache2
sudo apt update && sudo apt install haproxy && sudo systemctl enable haproxy

# Configuración de haproxy
sudo vim /etc/haproxy/haproxy.cfg
