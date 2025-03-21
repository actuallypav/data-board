#!/bin/bash
# Update & install dependencies
sudo apt update -y
sudo apt install -y docker docker-compose nginx

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Run Metabase container on port 3000
sudo docker run -d -p 3000:3000 --name metabase metabase/metabase

# Configure Nginx as reverse proxy
cat <<EOT > /etc/nginx/sites-available/metabase
server {
    listen 80;
    server_name metabase.example.com; # Change to your actual domain

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

# Enable Nginx site config
sudo ln -s /etc/nginx/sites-available/metabase /etc/nginx/sites-enabled/
sudo systemctl restart nginx
