#!/bin/bash

# Script de instalación de Apache

# Actualización de paquetes e instalación de apache2
sudo apt update && sudo apt install apache2 && sudo systemctl enable apache2

# Instalación de nano
sudo apt install nano

# Copiar anterior index.html 
sudo cp /var/www/html/index.html /var/www/html/index.old.html

# Creación de index
sudo nano /var/www/html/index.html

# Creación de index con cat
sudo cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Backend 1 Info</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f9;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background-color: #ffffff;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        h1 {
            font-size: 2.5rem;
            color: #333333;
        }
        .backend-3 {
            color: red;
        }
        p {
            font-size: 1.2rem;
            color: #666666;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="backend-3">Estás en el <span>Backend 3</span></h1>
        <p>Esta página se está sirviendo desde el Backend 3.</p>
    </div>
</body>
</html>
EOF