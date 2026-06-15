FROM node:18-alpine AS builder
RUN npm install -g firebase-tools
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y curl unzip && \
    curl -sLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz && \
    tar xf flutter_linux_3.27.1-stable.tar.xz && \
    export PATH="$PATH:`pwd`/flutter/bin" && \
    flutter config --enable-web && \
    flutter build web --release
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
