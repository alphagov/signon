ARG base_image=ruby:2.7.6-slim-bullseye

FROM $base_image AS builder
ENV RAILS_ENV=production \
    NODE_ENV=production \
    GOVUK_APP_DOMAIN=www.gov.uk \
    GOVUK_WEBSITE_ROOT=https://www.gov.uk \
    ASSETS_PREFIX=/assets/signon \
    BOOTSNAP_CACHE_DIR=/var/cache/bootsnap
# TODO: have a separate build image which already contains the build-only deps.
RUN apt-get update -qy && \
    apt-get upgrade -y && \
    apt-get clean
RUN apt-get install -y build-essential nodejs gnupg2 curl libmariadb-dev-compat
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get install -y yarn

RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle config set without 'development test' && \
    bundle install -j8 --retry=2

COPY . /app

RUN bundle exec bootsnap precompile --gemfile -v .
RUN DEVISE_PEPPER=unused DEVISE_SECRET_KEY=unused bundle exec rails assets:precompile


FROM $base_image
ENV RAILS_ENV=production \
    NODE_ENV=production \
    GOVUK_APP_NAME=signon \
    ASSETS_PREFIX=/assets/signon \
    BOOTSNAP_CACHE_DIR=/var/cache/bootsnap
WORKDIR /app

# TODO: have an up-to-date base image and stop running apt-get upgrade here.
RUN apt-get update -qy && \
    apt-get upgrade -y && \
    apt-get clean
RUN apt-get install -y libmariadb3

RUN echo 'IRB.conf[:HISTORY_FILE] = "/tmp/irb_history"' > irb.rc
COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/share/nodejs/ /usr/share/nodejs/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /var/cache/bootsnap/ /var/cache/
COPY --from=builder /app ./

RUN groupadd -g 1001 app && \
    useradd -u 1001 -g app app
USER 1001
CMD bundle exec puma
