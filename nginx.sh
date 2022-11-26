#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
cat <<EOT > luftbornapp
upstream luftbornapp {

 server appserver.com:8080;

}

server {

  listen 80;

location / {

  proxy_pass http://luftbornapp;

}
}

EOT

sudo mv luftbornapp /etc/nginx/sites-available/luftbornapp
sudo rm -rf /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/luftbornapp /etc/nginx/sites-enabled/luftbornapp

#starting nginx service and firewall
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
