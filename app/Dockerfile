FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
WORKDIR /usr/share/nginx/html
RUN rm -rf ./index.html
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
