FROM ghcr.io/devops-from-root/alpine:main

# Устанавливаем значения переменных
ARG BACK_URI=localhost
ENV BACK_URI=${BACK_URI}

# Устанавливаем необходимые пакеты
RUN apk add --no-cache openssl gettext netcat-openbsd

# Создаем  директорию для сертификатов
RUN mkdir -p /etc/nginx/ssl

# Генерируем самоподписанный сертификат
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/CN=${BACK_URI}"

# Создаем конфигурацию nginx.template через echo
RUN echo 'server {\n\
    listen 443 ssl;\n\
    server_name _default;\n\
\n\
    ssl_certificate /etc/nginx/ssl/nginx.crt;\n\
    ssl_certificate_key /etc/nginx/ssl/nginx.key;\n\
\n\
    location / {\n\
        proxy_pass http://${BACK_URI};\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
}' > /etc/nginx/nginx.template

# Запуск Nginx с заменой переменных окружения
CMD ["sh", "-c", "envsubst '$BACK_URI' < /etc/nginx/nginx.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
