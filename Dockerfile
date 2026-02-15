FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y \
  build-essential git curl unzip default-jre-headless libyaml-dev ghostscript \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock zugpferd.gemspec ./
RUN mkdir -p lib && touch lib/zugpferd.rb
RUN bundle install

CMD ["bundle", "exec", "rake", "test"]
