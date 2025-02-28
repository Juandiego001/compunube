#!/bin/bash

# Crear instancia de imagen de Ubuntu
echo "Crear instancia de imagen de Ubuntu..."
lxc init images:alpine/3.18/cloud c1

# Observar las IPS creadas
lxc network list

# Establecer IP estática en el servidor Ubuntu corriendo
echo "Establecer IP estática en el servidor Ubuntu corriendo"
lxc network attach lxdbr0 c1 eth0 eth0
lxc config device set c1 eth0 ipv4.address 10.3.222.2 # Cambiar aquí la IP

# Iniciar instancia de Ubuntu creada
echo "Iniciar instancia de Ubuntu creada..."
lxc start c1

# Instalar git y pip en máquina desplegada
echo "Instalar git y pip en máquina desplegada..."
lxc exec c1 -- apk update
lxc exec c1 -- apk add py-pip git

# Clonar el repositorio de render.com e instalar dependencias
echo "Clonar el repositorio de render.com e instalar dependencias..."
lxc exec c1 -- git clone https://github.com/render-examples/flask-hello-world
lxc exec c1 -- pip install -r flask-hello-world/requirements.txt

# Ejecutar gunicorn
echo "Ejecutar gunicorn..."
lxc exec c1 -- sh -c "cd flask-hello-world && gunicorn app:app --bind=0.0.0.0"
