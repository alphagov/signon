ARG ruby_version=3.1.2
ARG base_image=ghcr.io/alphagov/govuk-ruby-base:$ruby_version
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:$ruby_version


FROM $builder_image AS builder

ENV ASSETS_PREFIX=/assets/signon

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle install

COPY . /app
RUN bundle exec bootsnap precompile --gemfile .
RUN DEVISE_PEPPER=unused DEVISE_SECRET_KEY=unused \
        bundle exec rails assets:precompile && \
    rm -fr /app/log


FROM $base_image

ENV ASSETS_PREFIX=/assets/signon
ENV GOVUK_APP_NAME=signon

WORKDIR /app

COPY --from=builder /usr/bin/node* /usr/bin/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /var/cache/bootsnap/ /var/cache/
COPY --from=builder /app ./

USER app
CMD ["bundle", "exec", "puma"]
