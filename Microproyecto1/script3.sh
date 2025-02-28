#!/bin/bash

# Aprovisionamiento para server2

# Agregar repositorio de Hashi Corp
echo "Agregando repositorio de Hashi Corp..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Actualizar los paquetes
echo "Actualizando paquetes..."
apt update

# Instalación de Consul
echo "Instalando Consul..."
apt install consul -y

# Verificación de instalación de Consul
echo "Verificación de instalación de Consul..."
consul -v

# Instalando Unzip para fnm
echo "Instalando Unzip para fnm..."
apt install unzip -y

# Instalando Node.js
echo "Instalando Node.js..."

# Download and install fnm:
curl -o- https://fnm.vercel.app/install | bash

# Actualización de las variables de entorno
FNM_PATH="/root/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
eval "`fnm env`"

# Actualización de las variables de entorno para el usuario vagrant
echo "Actualizando variables de entorno para el usuario vagrant..."
mkdir -p /home/vagrant/.local/share/fnm
cp -r /root/.local/share/fnm /home/vagrant/.local/share/
cat << EOF >> /home/vagrant/.bashrc
# fnm
FNM_PATH="/home/vagrant/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi
EOF
echo "source /home/vagrant/.bashrc" >> /home/vagrant/.bash_profile

# Download and install Node.js:
fnm install 22

# Verify the Node.js version:
echo "Versión de Node.js: "
node -v # Should print "v22.14.0".

# Verify npm version:
echo "Versión de npm: "
npm -v # Should print "10.9.2".

# Creando archivo consul.log
echo "Creando archivo consul.log..."
touch /var/log/consul.log
chown vagrant:vagrant /var/log/consul.log

# Creando archivo consul_client.json
echo "Creando archivo consul_client.json..."
cat <<EOF > consul_client.json
{
  "node_name": "consul-client",
  "server": false,
  "retry_join": ["192.168.100.3"],
  "bind_addr": "192.168.100.4",
  "ui_config": {
    "enabled": true
  },
  "datacenter": "dc1",
  "data_dir": "tmp/consul",
  "log_file": "/var/log/consul.log",
  "log_level": "INFO",
  "addresses": {
    "http": "0.0.0.0"
  },
  "connect": {
    "enabled": true
  }
}
EOF
chown vagrant:vagrant consul_client.json

# Iniciar agente de Consul
echo "Iniciando agente de Consul..."
sudo nohup consul agent -config-file=consul_client.json &>/var/log/consul.log &

# Creación de archivo index.js
echo "Creando archivo index.js..."
mkdir app
touch app/index.js

# Escribir archivo index.js
echo "Escribiendo archivo index.js..."
sudo tee app/index.js << EOF
const Consul = require('consul');
const express = require('express');

const SERVICE_NAME = 'mymicroservice';
const SERVICE_ID = 'm' + process.argv[2];
const SCHEME = 'http';
const HOST = '192.168.100.4';
const PORT = process.argv[2] * 1;
const PID = process.pid;

/* Inicializacion del server */
const app = express();
const consul = new Consul();

app.get('/health', function (req, res) {
  console.log('Health check!');
  res.end("Ok.");
});

app.get('/', (req, res) => {
  console.log('GET /', Date.now());
  res.json({
    data: Math.floor(Math.random() * 89999999 + 10000000),
    data_pid: PID,
    data_service: SERVICE_ID,
    data_host: HOST
  });
});

app.listen(PORT, function () {
  console.log('Servicio iniciado en:' + SCHEME + '://' + HOST + ':' + PORT + '!');
});

/* Registro del servicio */
var check = {
  id: SERVICE_ID,
  name: SERVICE_NAME,
  address: HOST,
  port: PORT,
  check: {
    http: SCHEME + '://' + HOST + ':' + PORT + '/health',
    ttl: '5s',
    interval: '5s',
    timeout: '5s',
    deregistercriticalserviceafter: '1m'
  }
};

consul.agent.service.register(check, function (err) {
  if (err) throw err;
});
EOF

# Instalación de paquetes
echo "Instalación de paquetes para index.js..."
(cd app && npm i express consul)

# Creación de carpetas de logs
echo "Creación de carpetas de logs..."
mkdir logs

# Inicialización de múltiples servicios
echo "Inicialización de múltiples servicios..."
nohup node app/index.js 3003 &>logs/service1.log &
nohup node app/index.js 3004 &>logs/service2.log &
nohup node app/index.js 3005 &>logs/service3.log &
