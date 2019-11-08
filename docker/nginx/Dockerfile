FROM nginx

RUN apt-get update -qq && apt-get -y install apache2-utils

ENV RAILS_ROOT /app
WORKDIR $RAILS_ROOT

RUN mkdir log

COPY public public/
COPY docker/nginx/docker_demo.conf /tmp/docker_demo.nginx
RUN envsubst '$RAILS_ROOT' < /tmp/docker_demo.nginx > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD [ "nginx", "-g", "daemon off;" ]
