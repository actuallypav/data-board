#!/bin/bash
sudo yum update -y
sudo yum install -y nginx certbot python3-certbot-nginx

sudo systemctl start nginx
sudo systemctl enable nginx

#configure Nginx reverse proxy for Metabase
cat <<EOF | sudo tee /etc/nginx/conf.d/metabase.conf
server {
    listen 80;
    server_name metabase.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo systemctl restart nginx

#issue SSL certificate with "Let's Encrypt"
sudo certbot --nginx -d metabase.example.com --non-interactive --agree-tos -m your-email@example.com

#setup automatic SSL renewal
echo "0 0 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab