lxc network attach lxdbr0 c1 eth0 eth0;
lxc config device set c1 eth0 ipv4.address 10.20.80.2;
lxc start c1;
lxc exec c1 -- apt-get update;
lxc exec c1 -- apt install python3 git python3-pip -y;
lxc exec c1 -- git clone https://github.com/render-examples/flask-hello-world;
lxc exec c1 -- pip install -r flask-hello-world/requirements.txt;
lxc exec c1 -- nohup sh -c "cd flask-hello-world && gunicorn app:app --bind=0.0.0.0"

# Regla IP Tables para redireccionar
sudo iptables -t nat -A PREROUTING -p udp --dport 8000 -j DNAT --to-destination 10.20.80.2:8000
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT