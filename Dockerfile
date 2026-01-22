# docker build -t nginx-proxy . && docker run -d -p 443:443 -e BACK_URI backend:12345 --name nginx-proxy nginx-proxy

FROM alpine:latest

# Set environment variables
# Устанавливаем значения переменных
ENV BACK_URI=localhost

# Install required packages
# Устанавливаем необходимые пакеты
RUN apk add --no-cache openssl curl netcat-openbsd nginx

# Create directory for certificates
# Создаем  директорию для сертификатов
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
# Генерируем самоподписанный сертификат
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=localhost"

# Generate nginx config
# Генерируем конфиг nginx
RUN echo -e "events {}\n\
http {\n\
 server {\n\
  listen 443 ssl;\n\
  ssl_certificate /etc/nginx/ssl/nginx.crt;\n\
  ssl_certificate_key /etc/nginx/ssl/nginx.key;\n\
  ssl_protocols TLSv1.2 TLSv1.3;\
  ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384';\
  ssl_prefer_server_ciphers on;\
  location / {\n\
   proxy_pass http://localhost;\n\
   proxy_set_header Host \$host;\n\
   proxy_set_header X-Real-IP \$remote_addr;\n\
   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\
   proxy_set_header X-Forwarded-Proto \$scheme;\n\
  }\n\
  access_log /proc/self/fd/1;\
  error_log /proc/self/fd/2;\
 }\n\
}" > /etc/nginx/nginx.conf

# Expose port 443
# Открываем порт 443
EXPOSE 443

# Replace localhost in config with BACK_URI variable value and start nginx
# Заменяем в конфиге localhost на значение переменной BACK_URI и запускаем nginx
CMD /bin/sh -c "sed -i 's/localhost/'$BACK_URI'/g' /etc/nginx/nginx.conf && nginx -g 'daemon off;'"
