FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

EXPOSE 3001
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
