#!/bin/bash
echo "EMAIL=${EMAIL}" >> /etc/environment

sudo yum update -y
sudo yum install -y nginx certbot python3-certbot-nginx

sudo systemctl start nginx
sudo systemctl enable nginx

if ! sudo file -s /dev/xvdf | grep -q "ext4"; then
    sudo mkfs -t ext4 /dev/xvdf
fi

sudo mkdir -p /mnt/metabase
sudo mount /dev/xvdf /mnt/metabase
echo "/dev/xvdf /mnt/metabase ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab # persists across reboots

#Run metabase with persistent storage
sudo docker run -d \
    --name metabase \
    -p 3000:3000 \
    -v /mnt/metabase:/metabase-data \
    -e "MB_DB_TYPE=mysql" \
    -e "MB_DB_DBNAME=metadata_db" \
    -e "MB_DB_PORT=3306" \
    -e "MB_DB_USER=${DB_USER}" \
    -e "MB_DB_PASS=${DB_PASS}" \
    -e "MB_DB_HOST=${DB_HOST}" \
    metabase/metabase

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
sudo certbot --nginx -d metabase.example.com --non-interactive --agree-tos -m ${EMAIL}

#setup automatic SSL renewal
echo "0 0 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab