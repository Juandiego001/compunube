#!/bin/bash

# Se instala Python 3
sudo apt-get update
sudo apt install -y build-essential python3-pip

# Se instala Jupyter Notebooks
pip3 install jupyter
export PATH="$HOME/.local/bin:$PATH"

# Se ejecuta Jupyter
jupyter notebook --ip=0.0.0.0 --allow-root


