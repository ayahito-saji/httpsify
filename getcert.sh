read -p "Please enter your domain (example.com): " domain

cat <<EOL > nginx.conf
server {
    listen      80;
    server_name ${domain};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri = 404;
    }
}
EOL

docker compose down > /dev/null 2>&1
echo "Starting nginx..."
docker compose up -d nginx > /dev/null 2>&1
echo "Successfully started nginx"

echo "Staring certbot..."
docker compose run certbot certonly --webroot -d ${domain} -w /var/www/certbot

if [ $? -ne 0 ]; then
    echo "Failed to generate certificate."
    docker compose down > /dev/null 2>&1    
    exit 1
fi

echo "Successfully generated certificate!"

docker compose down nginx > /dev/null 2>&1

read -p "Please enter your app port (3000): " port

cat <<EOL > nginx.conf
server {
    listen      80;
    server_name yourdomain.com;
    location ~ /.well-known/acme-challenge {
        root /var/www/certbot;
        allow all;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen      443 ssl;
    server_name ${domain};

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://172.17.0.1:${port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

echo "Successfully generated nginx.conf!"
echo "Run docker compose to start nginx and certbot to renew certificates."
echo "$ docker compose up -d"