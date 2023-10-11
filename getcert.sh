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

docker compose down
echo "Starting nginx..."
docker compose up -d nginx
echo "Successfully started nginx"

echo "Staring certbot..."
docker compose run certbot certonly --webroot -d ${domain} --register-unsafely-without-email