FROM ruby:2.6.5

RUN apt-get update && apt-get install -y build-essential curl cron logrotate gettext-base nano
RUN apt-get clean
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

ENV APP_DIR /app
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR

COPY ./Gemfile /Gemfile
COPY ./Gemfile.lock /Gemfile.lock

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

RUN gem install bundler -v 2.0.2

EXPOSE 3000
