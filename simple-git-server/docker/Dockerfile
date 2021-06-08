FROM nginx:1.19.7

RUN apt-get update && \
    apt-get install -y \
        fcgiwrap \
        apache2-utils \
        git

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY fcgiwrap-entrypoint.sh /docker-entrypoint.d/
COPY fcgiwrap.defaults /etc/default/fcgiwrap
COPY repo/ /tmp/content
COPY init-repo.sh /docker-entrypoint.d/05-init-git-repo.sh

RUN chmod +x /docker-entrypoint.d/05-init-git-repo.sh
