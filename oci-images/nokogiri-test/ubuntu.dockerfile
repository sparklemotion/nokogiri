FROM ubuntu:noble

# include_file debian-prelude.step
# -*- dockerfile -*-

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils


# include_file debian-git.step
# -*- dockerfile -*-

RUN apt-get install -y git-core


# include_file debian-libxml-et-al.step
# -*- dockerfile -*-

RUN apt-get install -y libxslt-dev libxml2-dev zlib1g-dev pkg-config
RUN apt-get install -y libyaml-dev # for psych 5


# include_file debian-ruby.step
# -*- dockerfile -*-

RUN apt-get install -y ruby ruby-dev bundler


# include_file bundle-install.step
# -*- dockerfile -*-

COPY Gemfile nokogiri/
COPY Gemfile.lock nokogiri/
COPY nokogiri.gemspec nokogiri/

RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" nokogiri/Gemfile.lock | tail -n 1)"
RUN cd nokogiri && bundle install


# for libxml2 canonicalization
ENV LANG=C.UTF-8
