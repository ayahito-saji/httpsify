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
docker compose run certbot certonly --webroot -d ${domain} -w /var/www/certbot --agree-tos --no-eff-email

docker compose down nginx > /dev/null 2>&1