ARG ruby_version=2.7.6
ARG base_image=bitnami/ruby:$ruby_version

FROM $base_image AS builder

# TODO: remove these once they're set in the base image.
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_BIN=$GEM_HOME/bin
ENV PATH=$BUNDLE_BIN/bin:$PATH
ENV BUNDLE_WITHOUT="development test"

# TODO: set these in the builder image.
ENV BUNDLE_IGNORE_MESSAGES=1
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_JOBS=12
ENV MAKEFLAGS=-j12

ENV ASSETS_PREFIX=/assets/signon
ENV BOOTSNAP_CACHE_DIR=/var/cache/bootsnap
ENV GOVUK_APP_DOMAIN=unused
ENV GOVUK_WEBSITE_ROOT=unused

# TODO: have a separate builder image which already contains the build-only deps.
RUN apt-get update -qy
RUN apt-get install -y --no-install-suggests --no-install-recommends \
    nodejs libmariadb-dev-compat

RUN ln -fs /tmp /app/tmp
WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN echo 'install: --no-document' >> /etc/gemrc && bundle install
COPY . /app
RUN bundle exec bootsnap precompile --gemfile .
RUN DEVISE_PEPPER=unused DEVISE_SECRET_KEY=unused bundle exec rails assets:precompile


FROM $base_image

# TODO: set these in the base image.
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_BIN=$GEM_HOME/bin
ENV PATH=$GEM_HOME/bin:$PATH
ENV BUNDLE_WITHOUT="development test"

ENV GOVUK_APP_NAME=signon
ENV ASSETS_PREFIX=/assets/signon
ENV BOOTSNAP_CACHE_DIR=/var/cache/bootsnap
ENV GOVUK_PROMETHEUS_EXPORTER=true

WORKDIR /app

RUN echo 'IRB.conf[:HISTORY_FILE] = "/tmp/irb_history"' > irb.rc
RUN ln -fs /tmp /app/tmp

# TODO: include libmariadb3 in the base image and stop running apt-get install here.
COPY --from=builder /var/lib/apt/lists/ /var/lib/apt/lists/
RUN apt-get install -y --no-install-suggests --no-install-recommends libmariadb3

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /var/cache/bootsnap/ /var/cache/
COPY --from=builder /app ./

RUN groupadd -g 1001 app && \
    useradd -u 1001 -g app app
USER 1001
CMD bundle exec puma
