#!/bin/bash

# Aprovisionamiento para server1

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
echo "Actualizando variables de entorno..."
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

# Creando archivo consul_server.json
echo "Creando archivo consul_server.json..."
cat <<EOF > consul_server.json
{
  "node_name": "consul-server",
  "server": true,
  "bootstrap": true,
  "bind_addr": "192.168.100.3",
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
chown vagrant:vagrant consul_server.json

# Iniciar agente de Consul
echo "Iniciando agente de Consul..."
sudo nohup consul agent -config-file=consul_server.json &>/var/log/consul.log &

# Creación de archivos para aplicación web
echo "Creando archivos para aplicación web..."
mkdir -p app/views/layouts
touch app/index.js
touch app/views/layouts/main.handlebars
touch app/views/index.handlebars

# Escribir archivo main.handlebars
echo "Escribiendo archivo main.handlebars..."
sudo tee app/views/layouts/main.handlebars << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Web App Node.js</title>
</head>
<body>

    {{{body}}}

</body>
</html>
EOF

# Escribir archivo index.handlebars
echo "Escribiendo archivo index.handlebars..."
sudo tee app/views/index.handlebars << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f9;
            color: #333;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .json-container {
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            padding: 20px;
            max-width: 400px;
            width: 100%;
        }
        .json-item {
            margin-bottom: 10px;
            padding: 10px;
            border-bottom: 1px solid #eee;
        }
        .json-item:last-child {
            border-bottom: none;
        }
        .json-key {
            font-weight: bold;
            color: #555;
        }
        .json-value {
            color: #007bff;
        }
    </style>
</head>
<body>
    <div class="json-container">
        <div class="json-item">
            <span class="json-key">Data:</span>
            <span class="json-value">{{json.data}}</span>
        </div>
        <div class="json-item">
            <span class="json-key">Data PID:</span>
            <span class="json-value">{{json.data_pid}}</span>
        </div>
        <div class="json-item">
            <span class="json-key">Data Service:</span>
            <span class="json-value">{{json.data_service}}</span>
        </div>
        <div class="json-item">
            <span class="json-key">Data Host:</span>
            <span class="json-value">{{json.data_host}}</span>
        </div>
    </div>
</body>
</html>
EOF

# Escribir archivo index.js
echo "Escribiendo archivo index.js..."
sudo tee app/index.js << EOF
const Consul = require('consul');
const { engine } = require('express-handlebars');
const express = require('express');

const SERVICE_NAME = 'mymicroservice';
const SERVICE_ID = 'm' + process.argv[2];
const SCHEME = 'http';
const HOST = '192.168.100.3';
const PORT = process.argv[2] * 1;
const PID = process.pid;

/* Inicializacion del server */
const app = express();

// Configurar Handlebars como motor de plantillas
app.engine('handlebars', engine()); // Registrar Handlebars como motor de plantillas
app.set('view engine', 'handlebars'); // Establecer Handlebars como el motor de vistas
app.set('views', '/home/vagrant/app/views'); // Carpeta donde estarán las vistas

const consul = new Consul();

app.get('/health', function (req, res) {
  console.log('Health check!');
  res.end("Ok.");
});

app.get('/', (req, res) => {
  console.log('GET /', Date.now());
  res.render('index', {
      title: 'Web App Node.js',
      json: {
        data: Math.floor(Math.random() * 89999999 + 10000000),
        data_pid: PID,
        data_service: SERVICE_ID,
        data_host: HOST
      }
    }
  )
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
(cd app && npm i express consul express-handlebars)

# Creación de carpetas de logs
echo "Creación de carpetas de logs..."
mkdir logs

# Se actualizan los permisos de la carpeta app
echo "Actualizando los permisos de la carpeta app..."
chown -R vagrant:vagrant app/

# Inicialización de múltiples servicios
echo "Inicialización de múltiples servicios..."
nohup node app/index.js 3000 &>logs/service1.log &
nohup node app/index.js 3001 &>logs/service2.log &
nohup node app/index.js 3002 &>logs/service3.log &
