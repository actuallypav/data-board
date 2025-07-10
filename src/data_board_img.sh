#!/bin/bash
echo "STEP1 initialising the build"

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -x

echo "EMAIL=${EMAIL}" >> /etc/environment
echo "DOMAIN=${DOMAIN}" >> /etc/environment

source /etc/environment

sudo yum update -y
sudo yum install -y nginx certbot python3-certbot-nginx mariadb105 docker

sudo systemctl start nginx
sudo systemctl enable nginx

if ! sudo file -s /dev/xvdf | grep -q "ext4"; then
    sudo mkfs -t ext4 /dev/xvdf
fi

sudo mkdir -p /mnt/grafana
sudo mount /dev/xvdf /mnt/grafana
echo "/dev/xvdf /mnt/grafana ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab # persists across reboots
sudo chown -R 472:472 /mnt/grafana

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker ec2-user

#run sql bootstrap logic
mysql -u "${DB_USER}" -p"${DB_PASS}" -h "${DB_HOST}" <<EOF
CREATE DATABASE IF NOT EXISTS visualization_db;

USE visualization_db;

CREATE TABLE IF NOT EXISTS central_heating (
    id INT AUTO_INCREMENT PRIMARY KEY,
    thingname VARCHAR(50),
    time BIGINT,
    humidity INT,
    temperature INT
);
EOF

#Run grafana with persistent storage
sudo docker run -d \
    --name grafana \
    -p 3000:3000 \
    -v /mnt/grafana:/var/lib/grafana \
    grafana/grafana-oss

#configure Nginx reverse proxy for Grafana
cat <<EOF | sudo tee /etc/nginx/conf.d/grafana.conf
server {
    listen 80;
    server_name dash.${DOMAIN};

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
sudo certbot --nginx -d data.${DOMAIN} --non-interactive --agree-tos -m ${EMAIL}

#setup automatic SSL renewal
echo "0 0 * * * root certbot renew --quiet" | sudo tee -a /etc/crontab
echo "Grafana setup complete!"