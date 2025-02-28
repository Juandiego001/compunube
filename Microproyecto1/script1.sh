#!/bin/bash

# Aprovisionamiento para loadBalancer

# Actualizar los paquetes
echo "Actualizando paquetes..."
apt update

# Instalando haproxy
apt install haproxy -y

# Habilitando haproxy
sudo systemctl enable haproxy

# Configurar haproxy
echo "Configurando haproxy..."
sudo tee /etc/haproxy/haproxy.cfg <<EOF

global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 504 /etc/haproxy/errors/504.http

backend backend_1
   balance roundrobin
   stats enable
   stats auth admin:admin
   stats uri /haproxy?stats
   server web1 192.168.100.3:3000 check
   server web2 192.168.100.3:3001 check
   server web3 192.168.100.3:3002 check
   server web4 192.168.100.4:3003 check
   server web5 192.168.100.4:3004 check
   server web6 192.168.100.4:3005 check

http-errors custom_errors
  errorfile 503 /etc/haproxy/custom_errors/503.http

frontend http
  bind *:80
  default_backend backend_1
  errorfiles custom_errors
EOF

# Se crea la carpeta de errores para mostrar la página personalizada de errores
echo "Creando carpeta de errores para haproxy..."
mkdir /etc/haproxy/custom_errors

# Se crea archivo de errores personalizada
echo "Creando archivo de errores personalizada..."
touch /etc/haproxy/custom_errors/503.http

# Se modifica archivo de errores personalizado
sudo tee -a /etc/haproxy/custom_errors/503.http << EOF
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Servicio No Disponible</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        .container {
            text-align: center;
            background-color: #fff;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        h1 {
            color: #d9534f;
            font-size: 2.5em;
            margin-bottom: 20px;
        }

        p {
            color: #333;
            font-size: 1.2em;
            margin-bottom: 30px;
        }

        .loader {
            border: 5px solid #f3f3f3;
            border-top: 5px solid #d9534f;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .footer {
            margin-top: 20px;
            font-size: 0.9em;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Servicio No Disponible</h1>
        <p>Lo sentimos, el servicio no está disponible en estos momentos. Por favor, espere e intente nuevamente más tarde.</p>
        <div class="loader"></div>
        <div class="footer">Gracias por su comprensión.</div>
    </div>
</body>
</html>
EOF

systemctl restart haproxy