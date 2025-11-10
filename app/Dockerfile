FROM nginx:alpine-otel
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /usr/share/nginx/html
RUN rm -rf ./index.html
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
