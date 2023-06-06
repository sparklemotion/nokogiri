FROM ruby:alpine3.12

# prelude
RUN apk update
RUN apk add bash build-base git perl

# valgrind
RUN apk add valgrind

# libxml-et-al
RUN apk add libxml2-dev libxslt-dev xmlsec-dev pkgconfig

# include_file bundle-install.step
# -*- dockerfile -*-

COPY Gemfile nokogiri/
COPY Gemfile.lock nokogiri/
COPY nokogiri.gemspec nokogiri/

RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" nokogiri/Gemfile.lock | tail -n 1)"
RUN cd nokogiri && bundle install

