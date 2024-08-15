FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  libxml2-dev \
  libxslt1-dev \
  zlib1g-dev

# Install dbmate
RUN curl -fsSL -o /usr/local/bin/dbmate https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 && \
  chmod +x /usr/local/bin/dbmate

WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY . .

CMD ["rackup", "config.ru", "-o", "0.0.0.0"]
