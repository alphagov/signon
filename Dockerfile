ARG base_image=ghcr.io/alphagov/govuk-ruby-base:2.7.6
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:2.7.6

FROM $builder_image AS builder

ENV ASSETS_PREFIX=/assets/signon
ENV BOOTSNAP_CACHE_DIR=/var/cache/bootsnap

RUN install_packages libmariadb-dev-compat

WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle install
RUN ln -fs /tmp /app/tmp
COPY . /app
RUN bundle exec bootsnap precompile --gemfile .
RUN DEVISE_PEPPER=unused DEVISE_SECRET_KEY=unused bundle exec rails assets:precompile


FROM $base_image

ENV GOVUK_APP_NAME=signon \
    ASSETS_PREFIX=/assets/signon \
    BOOTSNAP_CACHE_DIR=/var/cache/bootsnap

WORKDIR /app

RUN install_packages libmariadb3

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /var/cache/bootsnap/ /var/cache/
COPY --from=builder /app ./

RUN ln -fs /tmp /app/tmp

USER app

CMD bundle exec puma
