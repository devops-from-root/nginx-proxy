FROM ghcr.io/devops-from-root/alpine:main

# Устанавливаем значения переменных
ARG BACK_URI=localhost
ENV BACK_URI=${BACK_URI}

# Устанавливаем необходимые пакеты
RUN apk add --no-cache openssl netcat-openbsd nginx

# Создаем  директорию для сертификатов
RUN mkdir -p /etc/nginx/ssl

# Генерируем самоподписанный сертификат
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=localhost"

# Создаем конфигурацию nginx через echo
RUN cat <<EOF > /etc/nginx/nginx.conf
events {}

http {
    server {
        listen 443 ssl;
        server_name _default;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass http://${BACK_URI};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# Запуск Nginx
CMD ["nginx", "-g", "daemon off;"]