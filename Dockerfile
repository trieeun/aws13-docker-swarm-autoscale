FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY test.png /usr/share/nginx/html/test.png
EXPOSE 80
