FROM ghcr.io/rnters/heroku-rails:22-3.1.4

COPY Gemfile* ./

RUN bundle install --jobs 20 --retry 5
