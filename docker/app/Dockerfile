FROM ruby:2.6.5

# Install some basic tools
RUN apt-get update && apt-get install -y build-essential curl cron logrotate gettext-base nano
RUN apt-get clean

# Install yarn because Rails 6 is required
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# Create working directory
ENV APP_DIR /app
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR

# Define path to save installed Gem
ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Install bundler 2.0.2 if you use this version. Because Ruby 2.6.5 installed bundler 1.6.x
RUN gem install bundler -v 2.0.2

# Expose app to port 3000 on container
EXPOSE 3000
